import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/models/wishlist_item.dart';
import 'package:thryft/providers/interaction_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<WishlistItem> _items = [];

  WishlistProvider() {
    _init();
  }

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
          final p = Product(
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
          );
          return WishlistItem(
            product: p,
            savedAt: DateTime.parse(data['created_at'].toString()),
          );
        },
      ).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  List<WishlistItem> get wishlistItems => List.unmodifiable(_items);

  /// Flat product list — used by ProductCard to check isWishlisted.
  List<Product> get items => _items.map((i) => i.product).toList();

  bool isWishlisted(String productId) =>
      _items.any((i) => i.product.id == productId);

  Future<void> toggleWishlist(Product product) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // User must be logged in to wishlist items
      return;
    }
    final bool isCurrentlyWishlisted = isWishlisted(product.id);

    // Optimistic UI update for immediate feedback
    if (isCurrentlyWishlisted) {
      _items.removeWhere((i) => i.product.id == product.id);
    } else {
      _items.insert(0, WishlistItem(product: product, savedAt: DateTime.now()));
      await InteractionService().logInteraction(productId: product.id, type: 'wishlist');

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
      }
    } catch (e) {
      debugPrint("Error toggling wishlist: $e");
      // Revert optimistic update on failure (optional but good resilience)
      fetchWishlist();
    }
  }
}
