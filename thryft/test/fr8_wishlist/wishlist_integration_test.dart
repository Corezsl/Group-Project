// Tests for FR8 (wishlist) — integration tests using real Supabase.
// Verifies that wishlist operations work correctly with actual database,
// that authentication requirements are enforced, and that data persists properly.

import 'package:flutter_test/flutter_test.dart';

import '../helpers/supabase_test_client.dart';
import 'fr8_wishlist_test_helpers.dart';

void main() {
  // Skip the integration suite when test credentials haven't been provided
  if (!hasTestCredentials) {
    test(
      'FR8 wishlist integration tests',
      () {},
      skip:
          'No Supabase credentials - run '
          'flutter test --dart-define-from-file=.env.test test/fr8_wishlist',
    );
    return;
  }

  final ctx = Fr8WishlistTestContext('integration');

  setUpAll(ctx.setUpAll);
  tearDown(ctx.tearDown);
  tearDownAll(ctx.tearDownAll);

  // -------------------------------------------------------------------------
  // FR8 #1 - Adding item to wishlist
  // Input: User taps "Save/Wishlist" button on product detail page
  // Expected: Item added to wishlist, button shows "Saved" state, wishlist count increases
  // -------------------------------------------------------------------------
  group('FR8 #1 - Adding item to wishlist', () {
    test('adds item to wishlist and persists to database', () async {
      final listingId = await ctx.seedProduct(
        name: 'FR8 Add Test Product',
        price: 50.0,
      );

      // Verify item is not initially wishlisted
      expect(await ctx.isWishlisted(ctx.buyer1Id, listingId), isFalse);

      // Add item to wishlist
      await ctx.addToWishlist(ctx.buyer1Id, listingId);

      // Verify item is now wishlisted
      expect(await ctx.isWishlisted(ctx.buyer1Id, listingId), isTrue);

      // Verify wishlist contains the item
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer1Id);
      expect(wishlistItems.length, equals(1));
      expect(wishlistItems.first['listing_id'], equals(listingId));
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #2 - View wishlist page
  // Input: User navigates to wishlist via navigation menu
  // Expected: Wishlist page displays all saved items with product details
  // -------------------------------------------------------------------------
  group('FR8 #2 - View wishlist page', () {
    test('displays multiple items in wishlist', () async {
      final product1Id = await ctx.seedProduct(
        name: 'FR8 View Product 1',
        price: 25.0,
      );
      final product2Id = await ctx.seedProduct(
        name: 'FR8 View Product 2',
        price: 35.0,
      );

      // Add items to wishlist
      await ctx.addToWishlist(ctx.buyer1Id, product1Id);
      await ctx.addToWishlist(ctx.buyer1Id, product2Id);

      // Verify wishlist contains both items
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer1Id);
      expect(wishlistItems.length, equals(2));
      
      final listingIds = wishlistItems.map((item) => item['listing_id'] as String).toList();
      expect(listingIds, contains(product1Id));
      expect(listingIds, contains(product2Id));

      // Verify product details are included
      for (final item in wishlistItems) {
        expect(item['products'], isNotNull);
        expect(item['products']['name'], isA<String>());
        expect(item['products']['price'], isA<double>());
      }
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #3 - Remove from product page
  // Input: User taps "Remove from wishlist" on saved item's product page
  // Expected: Item removed from wishlist, button returns to "Save" state
  // -------------------------------------------------------------------------
  group('FR8 #3 - Remove from product page', () {
    test('removes item from wishlist when toggled', () async {
      final listingId = await ctx.seedProduct(
        name: 'FR8 Remove Product',
        price: 60.0,
      );

      // Add item first
      await ctx.addToWishlist(ctx.buyer1Id, listingId);
      expect(await ctx.isWishlisted(ctx.buyer1Id, listingId), isTrue);

      // Remove item
      await ctx.removeFromWishlist(ctx.buyer1Id, listingId);

      // Verify item is removed
      expect(await ctx.isWishlisted(ctx.buyer1Id, listingId), isFalse);
      
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer1Id);
      expect(wishlistItems, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #4 - Remove from wishlist page
  // Input: User taps remove button on item in wishlist page
  // Expected: Item removed from wishlist, page updates immediately
  // -------------------------------------------------------------------------
  group('FR8 #4 - Remove from wishlist page', () {
    test('removes specific item from wishlist with multiple items', () async {
      final product1Id = await ctx.seedProduct(
        name: 'FR8 Multi Product 1',
        price: 45.0,
      );
      final product2Id = await ctx.seedProduct(
        name: 'FR8 Multi Product 2',
        price: 55.0,
      );
      final product3Id = await ctx.seedProduct(
        name: 'FR8 Multi Product 3',
        price: 65.0,
      );

      // Add multiple items
      await ctx.addToWishlist(ctx.buyer1Id, product1Id);
      await ctx.addToWishlist(ctx.buyer1Id, product2Id);
      await ctx.addToWishlist(ctx.buyer1Id, product3Id);

      expect(await ctx.getWishlistItems(ctx.buyer1Id), hasLength(3));

      // Remove one item
      await ctx.removeFromWishlist(ctx.buyer1Id, product2Id);

      // Verify only specific item was removed
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer1Id);
      expect(wishlistItems.length, equals(2));
      
      final listingIds = wishlistItems.map((item) => item['listing_id'] as String).toList();
      expect(listingIds, contains(product1Id));
      expect(listingIds, isNot(contains(product2Id)));
      expect(listingIds, contains(product3Id));
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #5 - Duplicate wishlist addition
  // Input: User taps "Save" on already wishlisted item
  // Expected: No duplicate created, button remains "Saved"
  // -------------------------------------------------------------------------
  group('FR8 #5 - Duplicate wishlist addition', () {
    test('prevents duplicate entries across multiple attempts', () async {
      final listingId = await ctx.seedProduct(
        name: 'FR8 Duplicate Prevention Product',
        price: 80.0,
      );

      // Add item multiple times
      await ctx.addToWishlist(ctx.buyer1Id, listingId);
      await ctx.addToWishlist(ctx.buyer1Id, listingId);
      await ctx.addToWishlist(ctx.buyer1Id, listingId);

      // Should still only have one entry
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer1Id);
      expect(wishlistItems.length, equals(1));
      expect(wishlistItems.first['listing_id'], equals(listingId));
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #6 - Unauthenticated user attempts to wishlist
  // Input: Non-logged-in user attempts to save item or access wishlist
  // Expected: Operation blocked, user must be logged in
  // -------------------------------------------------------------------------
  group('FR8 #6 - Unauthenticated user attempts to wishlist', () {
    test('blocks operations for unauthenticated users', () async {
      final listingId = await ctx.seedProduct(
        name: 'FR8 Auth Test Product',
        price: 70.0,
      );

      // Test with invalid user ID
      const invalidUserId = '00000000-0000-0000-0000-000000000000';

      // Operations should fail or return empty results
      expect(await ctx.getWishlistItems(invalidUserId), isEmpty);
      
      // Adding to wishlist with invalid user should throw FK error
      expect(() async => await ctx.addToWishlist(invalidUserId, listingId), throwsException);
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #7 - Wishlisting non-existent listing
  // Input: User tries to save/remove item that no longer exists
  // Expected: Operation fails gracefully, error message displayed
  // -------------------------------------------------------------------------
  group('FR8 #7 - Wishlisting non-existent listing', () {
    test('handles operations on non-existent listings gracefully', () async {
      const nonExistentListingId = '00000000-0000-0000-0000-000000000001';

      // Operations should not throw errors
      expect(await ctx.isWishlisted(ctx.buyer1Id, nonExistentListingId), isFalse);
      
      expect(() async => await ctx.addToWishlist(ctx.buyer1Id, nonExistentListingId), throwsException);
      expect(await ctx.isWishlisted(ctx.buyer1Id, nonExistentListingId), isFalse);
      
      await ctx.removeFromWishlist(ctx.buyer1Id, nonExistentListingId);
      expect(await ctx.isWishlisted(ctx.buyer1Id, nonExistentListingId), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // FR8 #8 - Empty wishlist view
  // Input: User accesses wishlist with zero saved items
  // Expected: Empty state message displayed, no errors thrown
  // -------------------------------------------------------------------------
  group('FR8 #8 - Empty wishlist view', () {
    test('displays empty wishlist state correctly', () async {
      // Ensure user has no items in wishlist
      final wishlistItems = await ctx.getWishlistItems(ctx.buyer2Id);
      expect(wishlistItems, isEmpty);

      // Should be able to access wishlist without errors
      expect(wishlistItems, isA<List>());
      expect(wishlistItems.length, equals(0));
    });
  });
}
