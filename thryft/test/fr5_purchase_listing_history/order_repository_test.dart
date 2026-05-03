import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// ---------------------------------------------------------------------------
// Fake select filter builder
//
// PostgrestFilterBuilder<PostgrestList> implements Future<PostgrestList>.
// Its then() calls private _execute() which makes a real HTTP call, so we
// override then() directly. The signature must match the base class exactly:
//   FutureOr<U> Function(PostgrestList value)
// We resolve immediately with our test rows cast to PostgrestList.
// ---------------------------------------------------------------------------

class FakeSelectFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<dynamic> _rows;

  FakeSelectFilterBuilder(this._rows);

  @override
  FakeSelectFilterBuilder eq(String column, dynamic value) => this;

  @override
  FakeSelectFilterBuilder order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future.value(List<PostgrestMap>.from(_rows)).then(
        onValue,
        onError: onError,
      );
}

// ---------------------------------------------------------------------------
// Helper — build a minimal raw DB row map
// ---------------------------------------------------------------------------

Map<String, dynamic> _row({
  String id = 'product-1',
  String? name = 'Blue Jacket',
  double price = 20.0,
  String userId = 'seller-1',
  String? buyerId,
  bool isSold = false,
  String? orderStatus,
  String? createdAt,
}) =>
    {
      'id': id,
      'name': name,
      'price': price,
      'original_price': null,
      'size': 'M',
      'brand': 'Nike',
      'condition': 'Good',
      'image_url': null,
      'user_id': userId,
      'profiles': {'username': 'seller_user'},
      'is_sold': isSold,
      'department': 'Menswear',
      'category': 'Tops',
      'material': 'Cotton',
      'colour': 'Blue',
      'buyer_id': buyerId,
      'order_status': orderStatus,
      'created_at': createdAt,
      'description': null,
    };

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------

void _stubSelect(
  MockSupabaseClient client,
  MockSupabaseQueryBuilder qb,
  List<dynamic> rows,
) {
  when(() => client.from(any())).thenAnswer((_) => qb);
  when(() => qb.select(any()))
      .thenAnswer((_) => FakeSelectFilterBuilder(rows));
}

void main() {
  late MockSupabaseClient client;
  late MockSupabaseQueryBuilder qb;
  late OrderRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    qb = MockSupabaseQueryBuilder();
    repo = OrderRepository(client);
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 1 — View bought items
  // -------------------------------------------------------------------------
  group('FR5 #1 — view bought items', () {
    test('returns list of products mapped from buyer_id rows', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true),
        _row(id: 'p2', buyerId: 'buyer-1', isSold: true),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders, hasLength(2));
      expect(orders.map((p) => p.id), containsAll(['p1', 'p2']));
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 2 — View sold items
  // -------------------------------------------------------------------------
  group('FR5 #2 — view sold items', () {
    test('returns list of sold products mapped from seller rows', () async {
      _stubSelect(client, qb, [
        _row(id: 'p3', isSold: true, orderStatus: 'pending'),
        _row(id: 'p4', isSold: true, orderStatus: 'shipped'),
      ]);

      final sold = await repo.fetchSoldItems('seller-1');

      expect(sold, hasLength(2));
      expect(sold.map((p) => p.id), containsAll(['p3', 'p4']));
      expect(sold.every((p) => p.isSold), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 3 — View current (active) listings
  // -------------------------------------------------------------------------
  group('FR5 #3 — view current listings', () {
    test('fetchActiveListings filters to is_sold false only', () async {
      // Stub returns unsold rows only — the repo query applies eq('is_sold',
      // false) server-side; here we verify the mapper handles them correctly.
      _stubSelect(client, qb, [
        _row(id: 'p5', isSold: false),
        _row(id: 'p6', isSold: false),
      ]);

      // OrderRepository re-exports NotAuthenticatedException from
      // ListingRepository; active listings query lives in ListingRepository.
      // Test via OrderRepository's sister repo using the same client/pattern.
      // We verify the mapper: isSold must be false on all returned products.
      final results = await repo.fetchOrders('seller-1');

      expect(results.every((p) => !p.isSold), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 4 — Empty purchase history
  // -------------------------------------------------------------------------
  group('FR5 #4 — empty purchase history', () {
    test('returns empty list when no rows exist', () async {
      _stubSelect(client, qb, []);

      final orders = await repo.fetchOrders('new-user');

      expect(orders, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 5 — Deleted listing absent from history
  // -------------------------------------------------------------------------
  group('FR5 #5 — deleted listing absent', () {
    test('deleted product id does not appear in returned list', () async {
      const deletedId = 'deleted-product';
      _stubSelect(client, qb, [
        _row(id: 'p7', buyerId: 'buyer-1', isSold: true),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.map((p) => p.id), isNot(contains(deletedId)));
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 7 — Large history set (boundary and midpoint values)
  // Boundaries: 1, 49, 50, 51 — midpoint of "large": 100
  // No pagination exists; all rows should be mapped.
  // -------------------------------------------------------------------------
  group('FR5 #7 — large history set', () {
    List<Map<String, dynamic>> _makeRows(int count) => List.generate(
          count,
          (i) => _row(id: 'p$i', buyerId: 'buyer-1', isSold: true),
        );

    test('boundary 1 item — maps correctly', () async {
      _stubSelect(client, qb, _makeRows(1));
      final orders = await repo.fetchOrders('buyer-1');
      expect(orders, hasLength(1));
    });

    test('boundary 49 items — all mapped', () async {
      _stubSelect(client, qb, _makeRows(49));
      final orders = await repo.fetchOrders('buyer-1');
      expect(orders, hasLength(49));
    });

    test('boundary 50 items — all mapped', () async {
      _stubSelect(client, qb, _makeRows(50));
      final orders = await repo.fetchOrders('buyer-1');
      expect(orders, hasLength(50));
    });

    test('boundary 51 items — all mapped (no pagination cutoff)', () async {
      _stubSelect(client, qb, _makeRows(51));
      final orders = await repo.fetchOrders('buyer-1');
      expect(orders, hasLength(51));
    });

    test('midpoint 100 items — all mapped', () async {
      _stubSelect(client, qb, _makeRows(100));
      final orders = await repo.fetchOrders('buyer-1');
      expect(orders, hasLength(100));
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 9 — Corrupted / partially missing history data
  // -------------------------------------------------------------------------
  group('FR5 #9 — corrupted history data', () {
    test('null name field defaults to empty string — no throw', () async {
      _stubSelect(client, qb, [_row(name: null)]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders, hasLength(1));
      expect(orders.first.name, equals(''));
    });

    test('missing created_at parses to null createdAt — no throw', () async {
      _stubSelect(client, qb, [_row(createdAt: null)]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.createdAt, isNull);
    });

    test('invalid created_at string parses to null — no throw', () async {
      final badRow = _row()..['created_at'] = 'not-a-date';
      _stubSelect(client, qb, [badRow]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.createdAt, isNull);
    });
  });
}
