import 'package:thryft/models/product.dart';

class WishlistItem {
  final Product product;
  final DateTime savedAt;

  const WishlistItem({required this.product, required this.savedAt});
}
