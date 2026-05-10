// Tests for FR8 (wishlist) — viewing wishlist page.
// Verifies that users can view their wishlist correctly,
// that the wishlist displays items properly, and that the UI handles empty states.

import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/wishlist_provider.dart';

void main() {
  group('FR8 Wishlist View Tests', () {
    late WishlistProvider provider;

    setUp(() {
      provider = WishlistProvider.test();
    });

    // Helper to create a test product
    Product createTestProduct({
      String id = 'product-1',
      String name = 'Test Product',
      double price = 50.0,
      double? originalPrice,
      String? sellerId = 'seller-1',
    }) {
      return Product(
        id: id,
        name: name,
        price: price,
        originalPrice: originalPrice,
        size: 'M',
        brand: 'Test Brand',
        condition: 'Good',
        department: 'Tops',
        category: 'T-Shirts',
        material: 'Cotton',
        colour: 'Blue',
        sellerId: sellerId,
        sellerName: 'testseller',
      );
    }

    // -------------------------------------------------------------------------
    // FR8 #2 - View wishlist page
    // Input: User navigates to wishlist via navigation menu
    // Expected: Wishlist page displays all saved items with product details
    // -------------------------------------------------------------------------
    group('FR8 #2 - View wishlist page', () {
      test('wishlist items getter returns unmodifiable list', () {
        // Should be empty by default
        expect(provider.wishlistItems, isEmpty);
        expect(provider.wishlistItems, isA<List<Product>>());

        // Should be unmodifiable
        expect(() => provider.wishlistItems.add(createTestProduct()), throwsUnsupportedError);
        expect(() => provider.wishlistItems.clear(), throwsUnsupportedError);
      });

      test('items getter returns same as wishlistItems', () {
        // Both getters should return the same list
        expect(provider.items, equals(provider.wishlistItems));
        expect(provider.items, isA<List<Product>>());
        expect(provider.items, isEmpty);
      });
    });
  });
}
