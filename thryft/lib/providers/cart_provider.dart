import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/cart_item.dart';
import 'package:thryft/models/product.dart';
class CartProvider extends ChangeNotifier {
  String? _currentUserId;
  final List<CartItem> _items = [];

  CartProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      _handleUserChange(user?.id);
    });
    // Check initial state
    _handleUserChange(Supabase.instance.client.auth.currentUser?.id);
  }

  Future<void> _handleUserChange(String? userId) async {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _items.clear();
    
    // Load new user's cart from Supabase
    if (userId != null) {
      try {
        final data = await Supabase.instance.client
            .from('cart_items')
            .select('product_id')
            .eq('user_id', userId);
            
        if (data.isNotEmpty) {
          final productIds = data.map((row) => row['product_id'] as String).toList();
          
          final productsData = await Supabase.instance.client
              .from('products')
              .select('*, profiles(username)')
              .inFilter('id', productIds);
              
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
              sellerName: pData['profiles'] != null ? pData['profiles']['username']?.toString() : null,
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

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  Future<void> addItem(Product product) async {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index < 0) {
      // Optimistic update
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
