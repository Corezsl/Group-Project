import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/listing_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// ---------------------------------------------------------------------------
// Fake filter builder
//
// PostgrestFilterBuilder<T> is itself a Future, so Mock + thenReturn/thenAnswer
// on .then() conflicts with mocktail's internal stub-recording state.
// A Fake that tracks calls lets us verify interactions without that conflict.
// ---------------------------------------------------------------------------

class FakeMutateFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final List<String> eqCalls = [];

  @override
  FakeMutateFilterBuilder eq(String column, dynamic value) {
    eqCalls.add('$column=$value');
    return this;
  }

  // Awaiting the builder should resolve immediately with null (no body).
  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) =>
      Future<dynamic>.value(null).then(onValue, onError: onError);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _stubMutateChain(
  MockSupabaseClient client,
  MockSupabaseQueryBuilder qb,
  FakeMutateFilterBuilder filter,
) {
  when(() => client.from(any())).thenAnswer((_) => qb);
  when(() => qb.update(any())).thenAnswer((_) => filter);
  when(() => qb.delete()).thenAnswer((_) => filter);
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockUser user;
  late MockSupabaseQueryBuilder qb;
  late FakeMutateFilterBuilder mutateFilter;
  late ListingRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    user = MockUser();
    qb = MockSupabaseQueryBuilder();
    mutateFilter = FakeMutateFilterBuilder(); // fresh instance resets eqCalls

    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.id).thenReturn('user-123');

    repo = ListingRepository(client);
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 1 — Edit listing price (valid)
  // Boundary values: £0.01 (lower), £15 (midpoint), £10000 (upper)
  // -------------------------------------------------------------------------
  group('FR4 #1 — edit listing price', () {
    test('midpoint price £15 — update is called with new price', () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.updateListing(
        id: 'listing-1',
        userId: 'user-123',
        fields: {'price': 15.0},
      );

      verify(() => qb.update({'price': 15.0})).called(1);
    });

    test('boundary lower £0.01 — update is called', () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.updateListing(
        id: 'listing-1',
        userId: 'user-123',
        fields: {'price': 0.01},
      );

      verify(() => qb.update({'price': 0.01})).called(1);
    });

    test('boundary upper £10000 — update is called', () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.updateListing(
        id: 'listing-1',
        userId: 'user-123',
        fields: {'price': 10000.0},
      );

      verify(() => qb.update({'price': 10000.0})).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 2 — Edit listing description (valid)
  // -------------------------------------------------------------------------
  group('FR4 #2 — edit listing description', () {
    test('new description text appears in update payload', () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.updateListing(
        id: 'listing-1',
        userId: 'user-123',
        fields: {'description': 'Updated description text'},
      );

      verify(
        () => qb.update({'description': 'Updated description text'}),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 3 — Delete listing (valid, unsold)
  // -------------------------------------------------------------------------
  group('FR4 #3 — delete listing', () {
    test('delete is called and scoped to listing id and owner id', () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.deleteListing(
        id: 'listing-1',
        userId: 'user-123',
        isSold: false,
      );

      verify(() => qb.delete()).called(1);
      expect(mutateFilter.eqCalls, containsAll(['id=listing-1', 'user_id=user-123']));
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 6 — Delete sold listing (invalid)
  // -------------------------------------------------------------------------
  group('FR4 #6 — delete sold listing is blocked', () {
    test('throws ListingIsSoldException before any DB call', () async {
      expect(
        () => repo.deleteListing(
          id: 'listing-1',
          userId: 'user-123',
          isSold: true,
        ),
        throwsA(isA<ListingIsSoldException>()),
      );

      verifyNever(() => client.from(any()));
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 8 — Mark as sold (valid)
  // -------------------------------------------------------------------------
  group('FR4 #8 — mark as sold', () {
    test('update sets is_sold true, buyer_id, and order_status pending',
        () async {
      _stubMutateChain(client, qb, mutateFilter);

      await repo.markAsSold(id: 'listing-1', buyerId: 'buyer-456');

      verify(
        () => qb.update({
          'is_sold': true,
          'buyer_id': 'buyer-456',
          'order_status': 'pending',
        }),
      ).called(1);
      expect(mutateFilter.eqCalls, contains('id=listing-1'));
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 9 — Edit / delete while logged out (invalid)
  // -------------------------------------------------------------------------
  group('FR4 #9 — operation while logged out', () {
    setUp(() {
      when(() => auth.currentUser).thenReturn(null);
    });

    test('updateListing throws NotAuthenticatedException', () {
      expect(
        () => repo.updateListing(
          id: 'listing-1',
          userId: 'user-123',
          fields: {'price': 15.0},
        ),
        throwsA(isA<NotAuthenticatedException>()),
      );
      verifyNever(() => client.from(any()));
    });

    test('deleteListing throws NotAuthenticatedException', () {
      expect(
        () => repo.deleteListing(
          id: 'listing-1',
          userId: 'user-123',
          isSold: false,
        ),
        throwsA(isA<NotAuthenticatedException>()),
      );
      verifyNever(() => client.from(any()));
    });

    test('markAsSold throws NotAuthenticatedException', () {
      expect(
        () => repo.markAsSold(id: 'listing-1', buyerId: 'buyer-456'),
        throwsA(isA<NotAuthenticatedException>()),
      );
      verifyNever(() => client.from(any()));
    });
  });
}
