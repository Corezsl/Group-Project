import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/cart_item.dart';
import 'package:thryft/models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, List<CartItem>> _userCarts = {};
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

  void _handleUserChange(String? userId) {
    if (_currentUserId == userId) return;

    // Save current cart if we had a user
    if (_currentUserId != null) {
      _userCarts[_currentUserId!] = List.from(_items);
    }
    
    _currentUserId = userId;
    
    // Load new user's cart or clear it
    _items.clear();
    if (userId != null && _userCarts.containsKey(userId)) {
      _items.addAll(_userCarts[userId]!);
    }
    notifyListeners();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  void addItem(Product product) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index < 0) {
      _items.add(CartItem(product: product));
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
