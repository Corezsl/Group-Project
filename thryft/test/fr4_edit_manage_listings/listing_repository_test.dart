import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/listing_repository.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

// ---------------------------------------------------------------------------
// Test credentials — fixed per file so re-runs reuse the same auth user
// instead of creating a new one each time.
// ---------------------------------------------------------------------------
const _sellerEmail = 'fr4.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

const _buyerEmail = 'fr4.buyer@thryft-test.local';
const _buyerPassword = 'Thryft!test99';

/// Sign in if the user already exists, sign up on first run.
Future<String> _ensureSignedIn(SupabaseClient client) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: _sellerEmail,
      password: _sellerPassword,
    );
    return res.user!.id;
  } on AuthException {
    final res = await client.auth.signUp(
      email: _sellerEmail,
      password: _sellerPassword,
      data: {'username': 'fr4_seller'},
    );
    return res.user!.id;
  }
}

void main() {
  late SupabaseClient client;
  late ListingRepository repo;
  late String sellerId;
  late String buyerId;

  // Main product re-seeded before each group that needs a fresh state.
  late String productId;

  setUpAll(() async {
    client = await getTestClient();

    // Register / sign in the seller first.
    sellerId = await _ensureSignedIn(client);

    // Register / sign in the buyer to get a real auth.users UUID,
    // then switch back to the seller session for the actual tests.
    try {
      final res = await client.auth.signInWithPassword(
        email: _buyerEmail,
        password: _buyerPassword,
      );
      buyerId = res.user!.id;
    } on AuthException {
      final res = await client.auth.signUp(
        email: _buyerEmail,
        password: _buyerPassword,
        data: {'username': 'fr4_buyer'},
      );
      buyerId = res.user!.id;
    }

    // Switch back to seller — all repository calls run under their session.
    await _ensureSignedIn(client);

    repo = ListingRepository(client);
  });

  tearDownAll(() async {
    // Clean up all products created by the test seller in this run.
    await client.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  setUp(() async {
    // Fresh product for each test so mutations in one test don't bleed
    // into the next.
    productId = await seedProduct(
      client,
      sellerId: sellerId,
      name: 'FR4 Test Jacket',
    );
  });

  tearDown(() async {
    // Remove this test's product (best effort — tearDownAll also cleans up).
    await client
        .from('products')
        .delete()
        .eq('id', productId)
        .eq('user_id', sellerId);
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 1 — Edit listing price (valid)
  // Boundary values: £0.01 (lower), £15 (midpoint), £10000 (upper)
  // -------------------------------------------------------------------------
  group('FR4 #1 — edit listing price', () {
    test('midpoint price £15 — db row updated', () async {
      await repo.updateListing(
        id: productId,
        userId: sellerId,
        fields: {'price': 15.0},
      );

      final row = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect((row['price'] as num).toDouble(), 15.0);
    });

    test('boundary lower £0.01 — db row updated', () async {
      await repo.updateListing(
        id: productId,
        userId: sellerId,
        fields: {'price': 0.01},
      );

      final row = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect((row['price'] as num).toDouble(), 0.01);
    });

    test('boundary upper £10000 — db row updated', () async {
      await repo.updateListing(
        id: productId,
        userId: sellerId,
        fields: {'price': 10000.0},
      );

      final row = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect((row['price'] as num).toDouble(), 10000.0);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 2 — Edit listing description (valid)
  // -------------------------------------------------------------------------
  group('FR4 #2 — edit listing description', () {
    test('new description saved to db', () async {
      const newDesc = 'Updated description text';
      await repo.updateListing(
        id: productId,
        userId: sellerId,
        fields: {'description': newDesc},
      );

      final row = await client
          .from('products')
          .select('description')
          .eq('id', productId)
          .single();

      expect(row['description'], newDesc);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 3 — Delete listing (valid, unsold)
  // -------------------------------------------------------------------------
  group('FR4 #3 — delete listing', () {
    test('product is gone from db after delete', () async {
      await repo.deleteListing(
        id: productId,
        userId: sellerId,
        isSold: false,
      );

      final rows = await client
          .from('products')
          .select('id')
          .eq('id', productId);

      expect(rows, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 6 — Delete sold listing (invalid)
  // -------------------------------------------------------------------------
  group('FR4 #6 — delete sold listing is blocked', () {
    test('throws ListingIsSoldException before touching db', () {
      expect(
        () => repo.deleteListing(
          id: productId,
          userId: sellerId,
          isSold: true,
        ),
        throwsA(isA<ListingIsSoldException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 8 — Mark as sold (valid)
  // -------------------------------------------------------------------------
  group('FR4 #8 — mark as sold', () {
    test('is_sold, buyer_id and order_status all updated in db', () async {
      // Use the real buyer account so the FK to auth.users is satisfied
      // by a genuinely different user — matching the real purchase scenario.
      await repo.markAsSold(id: productId, buyerId: buyerId);

      final row = await client
          .from('products')
          .select('is_sold, buyer_id, order_status')
          .eq('id', productId)
          .single();

      expect(row['is_sold'], isTrue);
      expect(row['buyer_id'], buyerId);
      expect(row['order_status'], 'pending');
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 9 — Edit / delete while logged out (invalid)
  // -------------------------------------------------------------------------
  group('FR4 #9 — operation while logged out', () {
    setUp(() async {
      await client.auth.signOut();
    });

    tearDown(() async {
      // Sign back in so the next test group works normally.
      await _ensureSignedIn(client);
    });

    test('updateListing throws NotAuthenticatedException', () {
      expect(
        () => repo.updateListing(
          id: productId,
          userId: sellerId,
          fields: {'price': 1.0},
        ),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('deleteListing throws NotAuthenticatedException', () {
      expect(
        () => repo.deleteListing(
          id: productId,
          userId: sellerId,
          isSold: false,
        ),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });

    test('markAsSold throws NotAuthenticatedException', () {
      expect(
        () => repo.markAsSold(id: productId, buyerId: sellerId),
        throwsA(isA<NotAuthenticatedException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // FR4 Partition 5 — Edit another user's listing (RLS enforcement)
  // RLS policy: "Users can update their own products" checks auth.uid() = user_id.
  // Supabase returns 0 rows updated rather than throwing for UPDATE — so we
  // verify the row is unchanged after the call, not that an exception is thrown.
  // -------------------------------------------------------------------------
  group("FR4 #5 — edit another user's listing", () {
    test("update on a non-owned product does nothing (RLS silently filters)",
        () async {
      // Seed a product owned by the seller, then try to update it
      // with a mismatched userId. The repo sends the update; RLS filters
      // it out server-side so the price stays the same.
      final originalRow = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      // Call update — shouldn't throw, but also shouldn't change anything.
      await repo.updateListing(
        id: productId,
        userId: 'wrong-user',
        fields: {'price': 9999.0},
      );

      final afterRow = await client
          .from('products')
          .select('price')
          .eq('id', productId)
          .single();

      expect(afterRow['price'], originalRow['price']);
    });
  });
}
