import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/cart_item.dart';
import 'package:thryft/models/product.dart';

/// Manages shopping cart state and syncs it with the `cart_items` table in Supabase.
/// Uses a local-first approach: the UI list is updated immediately,
/// then the database write happens in the background.
///
/// Consumed via Provider by cart screens, the cart badge, and checkout.
class CartProvider extends ChangeNotifier {
  String? _currentUserId;       // Tracks the logged-in user; null when signed out.
  final List<CartItem> _items = []; // In-memory cart contents.

  /// On creation, starts listening for auth changes so the cart
  /// is automatically loaded/cleared on login/logout.
  CartProvider() {
    _initAuthListener();
  }

  /// Subscribes to Supabase auth state changes.
  /// Also fires once immediately for the current session (if any).
  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      _handleUserChange(user?.id);
    });
    _handleUserChange(Supabase.instance.client.auth.currentUser?.id);
  }

  /// Called whenever the authenticated user changes.
  /// Clears the old cart, then fetches the new user's cart from Supabase.
  Future<void> _handleUserChange(String? userId) async {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _items.clear();
    
    if (userId != null) {
      try {
        // 1. Get the product IDs that are in this user's cart.
        final data = await Supabase.instance.client
            .from('cart_items')
            .select('product_id')
            .eq('user_id', userId);
            
        if (data.isNotEmpty) {
          final productIds = data.map((row) => row['product_id'] as String).toList();
          
          // 2. Fetch full product details (+ seller name via join) for those IDs.
          //    Only unsold items are included — sold products are silently dropped.
          final productsData = await Supabase.instance.client
              .from('products')
              .select('*, profiles(username)')
              .inFilter('id', productIds)
              .eq('is_sold', false);
              
          for (var pData in productsData) {
            final product = Product(
              id: pData['id'].toString(),
              name: pData['name'].toString(),
              price: (pData['price'] as num).toDouble(),
              originalPrice: pData['original_price'] != null ? (pData['original_price'] as num).toDouble() : null,
              size: pData['size'].toString(),
              brand: pData['brand'].toString(),
              condition: pData['condition'].toString(),
              imageUrl: pData['image_url']?.toString(),
              sellerId: pData['user_id']?.toString(),
              sellerName: pData['profiles'] != null
                  ? pData['profiles']['username']?.toString()
                  : null,
              category: pData['category']?.toString() ?? 'Other',
              department: pData['department']?.toString() ?? 'All',
              material: pData['material'].toString(),
              colour: pData['colour'].toString(),
              description: pData['description']?.toString(),
            );
            _items.add(CartItem(product: product));
          }
        }
      } catch (e) {
        debugPrint('Error loading cart from Supabase: $e');
      }
    }
    notifyListeners();
  }

  // --------------- Public getters ---------------

  /// Unmodifiable snapshot of the cart — used by the cart screen's ListView.
  List<CartItem> get items => List.unmodifiable(_items);

  /// Total number of items (respects quantity) — drives the badge count.
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Sum of (price × quantity) for every item — shown at checkout.
  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  /// Checks if a specific product is already in the cart.
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  

  /// Adds a product to the cart (if not already present) and
  /// inserts a row into `cart_items` in Supabase.
  Future<void> addItem(Product product) async {
    if (!isInCart(product.id)) {
      _items.add(CartItem(product: product));
      notifyListeners();

      if (_currentUserId != null) {
        try {
          await Supabase.instance.client.from('cart_items').insert({
            'user_id': _currentUserId,
            'product_id': product.id,
          });
        } catch (e) {
          debugPrint('Error inserting cart item to Supabase: $e');
        }
      }
    }
  }

  /// Removes a single product from the cart and deletes the
  /// matching row in `cart_items` tablr
  Future<void> removeItem(String productId) async {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
    
    if (_currentUserId != null) {
      try {
        await Supabase.instance.client.from('cart_items')
            .delete()
            .eq('user_id', _currentUserId!)
            .eq('product_id', productId);
      } catch (e) {
        debugPrint('Error removing cart item from Supabase: $e');
      }
    }
  }

  /// Empties the entire cart locally and deletes all of
  /// this user's rows from `cart_items`. Called after checkout.
  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    
    if (_currentUserId != null) {
      try {
        await Supabase.instance.client.from('cart_items')
            .delete()
            .eq('user_id', _currentUserId!);
      } catch (e) {
        debugPrint('Error clearing cart items from Supabase: $e');
      }
    }
  }
}
