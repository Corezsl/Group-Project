import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/order_repository.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

const _sellerEmail = 'fr6.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

const _buyerEmail = 'fr6.buyer@thryft-test.local';
const _buyerPassword = 'Thryft!test99';

// Uses the admin client to create the user when they don't exist yet,
// bypassing email confirmation and avoiding rate limits.
Future<String> _signInOrSignUp(
  SupabaseClient client,
  SupabaseClient admin,
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
    await admin.auth.admin.createUser(AdminUserAttributes(
      email: email,
      password: password,
      emailConfirm: true,
      userMetadata: {'username': username},
    ));
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  }
}

void main() {
  if (!hasTestCredentials) {
    test('FR6 integration tests', () {},
        skip: 'No Supabase credentials — pass '
            '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late SupabaseClient admin;
  late OrderRepository repo;
  late String sellerId;
  late String buyerId;

  setUpAll(() async {
    client = await getTestClient();
    admin = getServiceClient();

    sellerId = await _signInOrSignUp(
        client, admin, _sellerEmail, _sellerPassword, 'fr6_seller');
    buyerId = await _signInOrSignUp(
        client, admin, _buyerEmail, _buyerPassword, 'fr6_buyer');

    // Run tests as the seller so RLS allows product reads.
    await _signInOrSignUp(client, admin, _sellerEmail, _sellerPassword, 'fr6_seller');

    repo = OrderRepository(client);
  });

  tearDownAll(() async {
    await admin.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  // ---------------------------------------------------------------------------
  // FR6 Partition 1 — Valid purchase: item marked as sold with pending status
  // ---------------------------------------------------------------------------
  group('FR6 #1 — valid purchase sets order status to pending', () {
    late String p1;

    setUp(() async {
      p1 = await seedProduct(client, sellerId: sellerId, name: 'FR6 P1 Jacket');
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'pending',
      }).eq('id', p1);
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', p1);
    });

    test('order_status pending is returned via fetchOrders', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == p1);
      expect(product.orderStatus, equals('pending'));
      expect(product.isSold, isTrue);
    });

    test('sold item is linked to buyer via buyerId field', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == p1);
      expect(product.buyerId, equals(buyerId));
    });
  });

  // ---------------------------------------------------------------------------
  // FR6 Partition 2 — Valid shipping update: status changes to shipped
  // ---------------------------------------------------------------------------
  group('FR6 #2 — valid shipping update', () {
    late String p2;

    setUp(() async {
      p2 = await seedProduct(client, sellerId: sellerId, name: 'FR6 P2 Shirt');
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'shipped',
      }).eq('id', p2);
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', p2);
    });

    test('order_status shipped is returned via fetchOrders', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == p2);
      expect(product.orderStatus, equals('shipped'));
    });

    test('shipped item is still marked as sold', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == p2);
      expect(product.isSold, isTrue);
      expect(product.orderStatus, equals('shipped'));
    });
  });

  // ---------------------------------------------------------------------------
  // FR6 Partition 3 — Valid received update: status changes to delivered
  // ---------------------------------------------------------------------------
  group('FR6 #3 — valid received update', () {
    late String p3;

    setUp(() async {
      p3 = await seedProduct(client, sellerId: sellerId, name: 'FR6 P3 Trousers');
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'delivered',
      }).eq('id', p3);
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', p3);
    });

    test('order_status delivered is returned via fetchOrders', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == p3);
      expect(product.orderStatus, equals('delivered'));
    });

    test('delivered status is returned via fetchSoldItems for seller', () async {
      final sold = await repo.fetchSoldItems(sellerId);
      final product = sold.firstWhere((p) => p.id == p3);
      expect(product.orderStatus, equals('delivered'));
    });
  });

  // ---------------------------------------------------------------------------
  // FR6 Partition 4 — View order status: system returns current tracking status
  // ---------------------------------------------------------------------------
  group('FR6 #4 — view order status returns all statuses correctly', () {
    late String pPending;
    late String pShipped;
    late String pDelivered;
    late String pNullStatus;
    late String pTimestamp;

    setUp(() async {
      pPending = await seedProduct(
          client, sellerId: sellerId, name: 'FR6 P4 Pending');
      pShipped = await seedProduct(
          client, sellerId: sellerId, name: 'FR6 P4 Shipped');
      pDelivered = await seedProduct(
          client, sellerId: sellerId, name: 'FR6 P4 Delivered');
      pNullStatus = await seedProduct(
          client, sellerId: sellerId, name: 'FR6 P4 NullStatus');
      pTimestamp = await seedProduct(
          client, sellerId: sellerId, name: 'FR6 P4 Timestamp');

      for (final entry in {
        pPending: 'pending',
        pShipped: 'shipped',
        pDelivered: 'delivered',
      }.entries) {
        await client.from('products').update({
          'is_sold': true,
          'buyer_id': buyerId,
          'order_status': entry.value,
        }).eq('id', entry.key);
      }

      // Null order_status — sold but no status set.
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': null,
      }).eq('id', pNullStatus);

      // Timestamp test — mark sold so it appears in fetchOrders.
      await client.from('products').update({
        'is_sold': true,
        'buyer_id': buyerId,
        'order_status': 'shipped',
      }).eq('id', pTimestamp);
    });

    tearDown(() async {
      await admin
          .from('products')
          .delete()
          .inFilter('id', [pPending, pShipped, pDelivered, pNullStatus, pTimestamp]);
    });

    test('all three order statuses are returned in fetchOrders', () async {
      final orders = await repo.fetchOrders(buyerId);
      final ids = orders.map((p) => p.id).toList();
      expect(ids, containsAll([pPending, pShipped, pDelivered]));
      expect(
        orders
            .where((p) => [pPending, pShipped, pDelivered].contains(p.id))
            .map((p) => p.orderStatus),
        containsAll(['pending', 'shipped', 'delivered']),
      );
    });

    test('null order_status maps to null — no throw', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == pNullStatus);
      expect(product.orderStatus, isNull);
    });

    test('timestamps are mapped and returned with the order', () async {
      final orders = await repo.fetchOrders(buyerId);
      final product = orders.firstWhere((p) => p.id == pTimestamp);
      expect(product.createdAt, isNotNull);
      expect(product.createdAt, isA<DateTime>());
    });

    test('multiple orders are all returned in the list', () async {
      final orders = await repo.fetchOrders(buyerId);
      final ids = orders.map((p) => p.id).toList();
      expect(ids, containsAll([pPending, pShipped, pDelivered, pNullStatus]));
    });
  });
}
