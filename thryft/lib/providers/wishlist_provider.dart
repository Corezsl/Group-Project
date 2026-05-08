import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/providers/notification_provider.dart';

/// Manages the user's wishlist state and synchronizes it with the Supabase `wishlist` table.
/// It provides functionality to fetch the user's wishlisted items, toggle items on/off the wishlist,
/// and handles sending notifications to sellers when their items are wishlisted.
/// 
/// Used throughout the app wherever products are displayed (like the Home Screen, Search Screen, 
/// or Product Details Screen) to show the heart icon's status and allow users to save items.
class WishlistProvider extends ChangeNotifier {
  List<Product> _items = [];

  WishlistProvider() {
    _init();
  }

  WishlistProvider.test();

  /// Initializes the provider by setting up an auth state listener.
  /// Automatically fetches the wishlist when a user logs in and clears it when they log out.
  Future<void> _init() async {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchWishlist();
      } else {
        _items.clear();
        notifyListeners();
      }
    });

    // Initial fetch if already logged in
    if (Supabase.instance.client.auth.currentUser != null) {
      fetchWishlist();
    }
  }

  /// Fetches the current user's wishlisted items from the Supabase database.
  /// It joins the `wishlist` table with the `products` and `profiles` tables
  /// to get complete product details (like price, image) and seller usernames.
  Future<void> fetchWishlist() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('wishlist')
          .select('created_at, products(*, profiles(username))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _items = (response as List).where((data) => data['products'] != null).map(
        (data) {
          final pData = data['products'];
          return Product(
            id: pData['id'].toString(),
            name: pData['name'].toString(),
            price: (pData['price'] as num).toDouble(),
            originalPrice: pData['original_price'] != null
                ? (pData['original_price'] as num).toDouble()
                : null,
            size: pData['size'].toString(),
            brand: pData['brand'].toString(),
            condition: pData['condition'].toString(),
            imageUrl: pData['image_url']?.toString(),
            sellerId: pData['user_id']?.toString(),
            sellerName: pData['profiles'] != null
                ? pData['profiles']['username']?.toString()
                : null,
            isSold: pData['is_sold'] == true,
            category: pData['category']?.toString() ?? 'Other',
            department: pData['department']?.toString() ?? 'All',
            material: pData['material'].toString(),
            colour: pData['colour'].toString(),
            description: pData['description']?.toString(),
          );
        },
      ).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  List<Product> get wishlistItems => List.unmodifiable(_items);

  /// Flat product list — used by ProductCard to check isWishlisted.
  List<Product> get items => List.unmodifiable(_items);

  /// Checks if a specific product ID exists in the user's local wishlist.
  bool isWishlisted(String productId) =>
      _items.any((p) => p.id == productId);

  /// Adds or removes a product from the wishlist.
  /// Uses an optimistic UI approach: it updates the local state immediately so the UI feels fast,
  /// and then performs the database operations in the background. Reverts if the DB operation fails.
  Future<void> toggleWishlist(Product product) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // User must be logged in to wishlist items
      return;
    }

    // Prevent users from wishlisting their own items
    if (product.sellerId != null && product.sellerId.toString() == userId) {
      final wasWishlisted = isWishlisted(product.id);
      if (wasWishlisted) {
        _items.removeWhere((p) => p.id == product.id);
        notifyListeners();

        // Remove the item from DB on wishlist table
        try {
          await Supabase.instance.client
              .from('wishlist')
              .delete()
              .eq('user_id', userId)
              .eq('listing_id', product.id);
        } catch (e) {
          debugPrint("Error removing own product from wishlist: $e");
          fetchWishlist();
        }

        debugPrint('Removed own product from wishlist (productId=${product.id})');
      } else {
        debugPrint('Attempt to wishlist own product prevented (productId=${product.id})');
      }
      return;
    }

    final bool isCurrentlyWishlisted = isWishlisted(product.id);

    // Optimistic UI update for immediate feedback
    if (isCurrentlyWishlisted) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _items.insert(0, product);
    }
    notifyListeners();

    // Database update
    try {
      if (isCurrentlyWishlisted) {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', product.id);
      } else {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': userId,
          'listing_id': product.id,
        });
        // Notify the seller that someone wishlisted their item
        if (product.sellerId != null) {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('username')
              .eq('id', userId)
              .maybeSingle();
          final username = profile?['username']?.toString() ?? 'Someone';
          await NotificationProvider.insertNotification(
            userId: product.sellerId!,
            type: NotificationType.wishlistAdd,
            content: '$username added your listing "${product.name}" to their wishlist.',
            listingId: product.id,
            relatedUserId: userId,
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling wishlist: $e");
      // Revert optimistic update on failure (optional but good resilience)
      fetchWishlist();
    }
  }
}
