import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/order_repository.dart';

// Mocks

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Fake select filter builder — same pattern as FR5 order_repository_test.

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

// Helper — build a minimal raw DB row map

Map<String, dynamic> _row({
  String id = 'product-1',
  String? name = 'Blue Jacket',
  double price = 20.0,
  String userId = 'seller-1',
  String? buyerId = 'buyer-1',
  bool isSold = true,
  String? orderStatus = 'pending',
  String? createdAt = '2026-01-01T00:00:00.000Z',
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

// Stub helpers

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

  // FR6 Partition 1 — Valid purchase: item marked as sold with pending status
  group('FR6 #1 — valid purchase sets order status to pending', () {
    test('order_status pending is mapped to product.orderStatus', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'pending'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders, hasLength(1));
      expect(orders.first.orderStatus, equals('pending'));
      expect(orders.first.isSold, isTrue);
    });

    test('sold item is linked to buyer via buyerId field', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'pending'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.buyerId, equals('buyer-1'));
    });
  });

  // FR6 Partition 2 — Valid shipping update: status changes to shipped

  group('FR6 #2 — valid shipping update', () {
    test('order_status shipped is mapped to product.orderStatus', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'shipped'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.orderStatus, equals('shipped'));
    });

    test('shipped item is still marked as sold', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'shipped'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.isSold, isTrue);
      expect(orders.first.orderStatus, equals('shipped'));
    });
  });

  // FR6 Partition 3 — Valid received update: status changes to delivered

  group('FR6 #3 — valid received update', () {
    test('order_status delivered is mapped to product.orderStatus', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'delivered'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.orderStatus, equals('delivered'));
    });

    test('sold items fetch returns delivered status via fetchSoldItems', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', userId: 'seller-1', isSold: true, orderStatus: 'delivered'),
      ]);

      final sold = await repo.fetchSoldItems('seller-1');

      expect(sold.first.orderStatus, equals('delivered'));
    });
  });

  // FR6 Partition 4 — View order status: system returns current tracking status

  group('FR6 #4 — view order status returns all three statuses correctly', () {
    test('all three order statuses are mapped and returned', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'pending'),
        _row(id: 'p2', buyerId: 'buyer-1', isSold: true, orderStatus: 'shipped'),
        _row(id: 'p3', buyerId: 'buyer-1', isSold: true, orderStatus: 'delivered'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders, hasLength(3));
      expect(
        orders.map((p) => p.orderStatus),
        containsAll(['pending', 'shipped', 'delivered']),
      );
    });

    test('null order_status maps to null — no throw', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: null),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.orderStatus, isNull);
    });

    test('timestamps are mapped and returned with the order', () async {
      const ts = '2026-03-15T10:30:00.000Z';
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'shipped', createdAt: ts),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.first.createdAt, equals(DateTime.parse(ts)));
    });

    test('multiple orders are returned in the list', () async {
      _stubSelect(client, qb, [
        _row(id: 'p1', buyerId: 'buyer-1', isSold: true, orderStatus: 'pending'),
        _row(id: 'p2', buyerId: 'buyer-1', isSold: true, orderStatus: 'delivered'),
      ]);

      final orders = await repo.fetchOrders('buyer-1');

      expect(orders.map((p) => p.id), containsAll(['p1', 'p2']));
    });
  });
}
