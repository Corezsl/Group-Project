import 'package:flutter/material.dart';
import 'package:thryft/models/product.dart';
import 'package:thryft/models/wishlist_item.dart';

class WishlistProvider extends ChangeNotifier {
  final List<WishlistItem> _items = [];

  List<WishlistItem> get wishlistItems => List.unmodifiable(_items);

  /// Flat product list — used by ProductCard to check isWishlisted.
  List<Product> get items => _items.map((i) => i.product).toList();

  bool isWishlisted(String productId) =>
      _items.any((i) => i.product.id == productId);

  void toggleWishlist(Product product) {
    if (isWishlisted(product.id)) {
      _items.removeWhere((i) => i.product.id == product.id);
    } else {
      _items.add(WishlistItem(product: product, savedAt: DateTime.now()));
    }
    notifyListeners();
  }
}
