import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// Helper: builds a valid product row map with sensible defaults.
// Override individual keys to test specific edge-case partitions.
// ---------------------------------------------------------------------------
Map<String, dynamic> _validRow([int index = 0]) => {
      'id': 'test-id-$index',
      'name': 'Product $index',
      'price': 10.0 + index,
      'original_price': null,
      'size': 'M',
      'brand': 'TestBrand',
      'condition': 'Good',
      'image_url': 'https://example.com/img$index.jpg',
      'user_id': 'seller-$index',
      'profiles': {'username': 'seller_user_$index'},
      'is_sold': true,
      'department': 'Men',
      'category': 'Tops',
      'material': 'Cotton',
      'colour': 'Blue',
      'buyer_id': 'buyer-$index',
      'order_status': 'pending',
      'created_at': '2026-01-01T00:00:00.000Z',
      'description': 'A test product $index',
    };

void main() {
  // -------------------------------------------------------------------------
  // FR5 Partition 7 — Large history set (boundary + midpoint)
  // Verifies that the mapper handles row counts at equivalence-class
  // boundaries: 1 (lower), 49, 50, 51 (boundary cluster around 50),
  // and 100 (midpoint of "large").
  // -------------------------------------------------------------------------
  group('FR5 #7 — mapper handles boundary set sizes', () {
    for (final count in [1, 49, 50, 51, 100]) {
      test('maps $count synthetic rows without error', () {
        final rows = List.generate(count, (i) => _validRow(i));
        final products = rows.map(OrderRepository.rowToProduct).toList();

        expect(products.length, count);
        // Verify every row produced a valid product with a non-empty id.
        for (var i = 0; i < count; i++) {
          expect(products[i].id, 'test-id-$i');
        }
      });
    }
  });

  // -------------------------------------------------------------------------
  // FR5 Partition 9 — Corrupted / malformed history data
  // Verifies that rowToProduct degrades gracefully on missing or invalid
  // field values without throwing.
  // -------------------------------------------------------------------------
  group('FR5 #9 — corrupted history data', () {
    test('name=null defaults to empty string', () {
      final row = _validRow()..['name'] = null;
      final product = OrderRepository.rowToProduct(row);
      expect(product.name, '');
    });

    test('created_at with invalid string results in null createdAt', () {
      final row = _validRow()..['created_at'] = 'not-a-date';
      final product = OrderRepository.rowToProduct(row);
      expect(product.createdAt, isNull);
    });

    test('created_at=null results in null createdAt', () {
      final row = _validRow()..['created_at'] = null;
      final product = OrderRepository.rowToProduct(row);
      expect(product.createdAt, isNull);
    });

    test('fully valid row maps all fields correctly', () {
      final product = OrderRepository.rowToProduct(_validRow(42));

      expect(product.id, 'test-id-42');
      expect(product.name, 'Product 42');
      expect(product.price, 52.0);
      expect(product.size, 'M');
      expect(product.brand, 'TestBrand');
      expect(product.condition, 'Good');
      expect(product.imageUrl, 'https://example.com/img42.jpg');
      expect(product.sellerId, 'seller-42');
      expect(product.sellerName, 'seller_user_42');
      expect(product.isSold, isTrue);
      expect(product.department, 'Men');
      expect(product.category, 'Tops');
      expect(product.material, 'Cotton');
      expect(product.colour, 'Blue');
      expect(product.buyerId, 'buyer-42');
      expect(product.orderStatus, 'pending');
      expect(product.createdAt, isNotNull);
      expect(product.description, 'A test product 42');
    });
  });
}
