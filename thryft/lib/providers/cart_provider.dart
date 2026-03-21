import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/cart_item.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/data/dummy_data.dart';

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
            
        for (var row in data) {
          final pId = row['product_id'] as String;
          try {
            final product = dummyProducts.firstWhere((p) => p.id == pId);
            _items.add(CartItem(product: product));
          } catch (_) {
            // Ignore if product ID not found in dummy data
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
