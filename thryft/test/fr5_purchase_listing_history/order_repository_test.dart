import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/order_repository.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

// ---------------------------------------------------------------------------
// Test credentials — fixed per file so re-runs reuse the same auth accounts.
// ---------------------------------------------------------------------------
const _sellerEmail = 'fr5.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

const _buyerEmail = 'fr5.buyer@thryft-test.local';
const _buyerPassword = 'Thryft!test99';

Future<String> _signInOrSignUp(
  SupabaseClient client,
  String email,
  String password,
  String username,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  } on AuthException {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return res.user!.id;
  }
}

void main() {
  // Skip the entire suite when --dart-define credentials haven't been supplied
  // (e.g. plain `flutter test` from the IDE). Run with run_integration_tests.ps1
  // or pass the flags manually to execute against the real test DB.
  if (!hasTestCredentials) {
    test('FR5 integration tests', () {}, skip: 'No Supabase credentials — pass '
        '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late OrderRepository repo;
  late String sellerId;
  late String buyerId;

  setUpAll(() async {
    client = await getTestClient();

    // Sign in / register both users. We only need their IDs here;
    // the actual repo calls don't require a specific session for read ops.
    sellerId = await _signInOrSignUp(client, _sellerEmail, _sellerPassword, 'fr5_seller');
    buyerId = await _signInOrSignUp(client, _buyerEmail, _buyerPassword, 'fr5_buyer');

    // Run tests as the seller (products are owned by the seller).
    await _signInOrSignUp(client, _sellerEmail, _sellerPassword, 'fr5_seller');

    repo = OrderRepository(client);
  });

  tearDownAll(() async {
    await client.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 1 — View bought items
  // -------------------------------------------------------------------------
  group('FR5 #1 — view bought items', () {
    late String p1;
    late String p2;

    setUp(() async {
      p1 = await seedProduct(client, sellerId: sellerId, name: 'FR5 Bought Jacket');
      p2 = await seedProduct(client, sellerId: sellerId, name: 'FR5 Bought Shirt');

      // Mark both as sold with the buyer as purchaser.
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'pending',
      }).eq('id', p1);

      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'shipped',
      }).eq('id', p2);
    });

    tearDown(() async {
      await client.from('products').delete().inFilter('id', [p1, p2]);
    });

    test('returns list of products purchased by buyer', () async {
      final orders = await repo.fetchOrders(buyerId);

      final ids = orders.map((p) => p.id).toList();
      expect(ids, containsAll([p1, p2]));
    });

    test('all returned products have isSold = true', () async {
      final orders = await repo.fetchOrders(buyerId);
      expect(orders.every((p) => p.isSold), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 2 — View sold items
  // -------------------------------------------------------------------------
  group('FR5 #2 — view sold items', () {
    late String p3;
    late String p4;

    setUp(() async {
      p3 = await seedProduct(client, sellerId: sellerId, name: 'FR5 Sold Pending');
      p4 = await seedProduct(client, sellerId: sellerId, name: 'FR5 Sold Shipped');

      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'pending',
      }).eq('id', p3);

      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'shipped',
      }).eq('id', p4);
    });

    tearDown(() async {
      await client.from('products').delete().inFilter('id', [p3, p4]);
    });

    test('returns sold products owned by seller', () async {
      final sold = await repo.fetchSoldItems(sellerId);

      final ids = sold.map((p) => p.id).toList();
      expect(ids, containsAll([p3, p4]));
    });

    test('all returned products have isSold = true', () async {
      final sold = await repo.fetchSoldItems(sellerId);
      final relevant = sold.where((p) => [p3, p4].contains(p.id));
      expect(relevant.every((p) => p.isSold), isTrue);
    });

    test('order_status is preserved correctly', () async {
      final sold = await repo.fetchSoldItems(sellerId);

      final pending = sold.firstWhere((p) => p.id == p3);
      final shipped = sold.firstWhere((p) => p.id == p4);

      expect(pending.orderStatus, 'pending');
      expect(shipped.orderStatus, 'shipped');
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 3 — Active (unsold) listings are not in order history
  // -------------------------------------------------------------------------
  group('FR5 #3 — unsold listings excluded from order history', () {
    late String unsoldId;

    setUp(() async {
      unsoldId = await seedProduct(
        client,
        sellerId: sellerId,
        name: 'FR5 Still For Sale',
        isSold: false,
      );
    });

    tearDown(() async {
      await client.from('products').delete().eq('id', unsoldId);
    });

    test('unsold product does not appear in fetchOrders result', () async {
      final orders = await repo.fetchOrders(buyerId);
      expect(orders.map((p) => p.id), isNot(contains(unsoldId)));
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 4 — Empty purchase history
  // -------------------------------------------------------------------------
  group('FR5 #4 — empty purchase history', () {
    test('returns empty list when buyer has no purchases', () async {
      // Use a random uuid that will never match a buyer_id in the test db.
      const ghostBuyer = '00000000-ffff-4000-8000-000000000000';
      final orders = await repo.fetchOrders(ghostBuyer);
      expect(orders, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 5 — Deleted listing absent from history
  // -------------------------------------------------------------------------
  group('FR5 #5 — deleted listing absent from history', () {
    test('deleted product does not appear in fetchOrders', () async {
      // Seed, mark sold, then hard-delete the product.
      final deletedId = await seedProduct(
        client,
        sellerId: sellerId,
        name: 'FR5 Delete Me',
      );

      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'pending',
      }).eq('id', deletedId);

      await client.from('products').delete().eq('id', deletedId);

      final orders = await repo.fetchOrders(buyerId);
      expect(orders.map((p) => p.id), isNot(contains(deletedId)));
    });
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 7 — Multiple items in history
  // Seeds 5 products and verifies all are returned (representative boundary).
  // (Seeding 100 rows in an integration test would be too slow; the mapper
  // logic for large sets is verified separately via unit tests.)
  // -------------------------------------------------------------------------
  group('FR5 #7 — multiple items in history', () {
    final seededIds = <String>[];

    setUp(() async {
      seededIds.clear();
      for (var i = 0; i < 5; i++) {
        final id = await seedProduct(
          client,
          sellerId: sellerId,
          name: 'FR5 Multi Product $i',
        );
        await client.from('products').update({
          'is_sold': true,
          'buyer_id': buyerId,
          'order_status': 'pending',
        }).eq('id', id);
        seededIds.add(id);
      }
    });

    tearDown(() async {
      if (seededIds.isNotEmpty) {
        await client.from('products').delete().inFilter('id', seededIds);
      }
    });

    test('all 5 seeded purchased products are returned', () async {
      final orders = await repo.fetchOrders(buyerId);
      final returnedIds = orders.map((p) => p.id).toList();
      expect(returnedIds, containsAll(seededIds));
    });
  });
}
