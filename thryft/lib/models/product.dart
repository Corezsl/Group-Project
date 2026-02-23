class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final double? originalPrice; // if set, card shows strikethrough old price
  final String size;
  final String brand;
  final String condition;

  const Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.size,
    required this.brand,
    required this.condition,
  });

  /// Convenience – convert to a simple map for GoRouter's [extra] parameter.
  Map<String, String> toRouteExtra() => {
    'id': id,
    'name': name,
    'price': price.toStringAsFixed(2),
    if (originalPrice != null)
      'originalPrice': originalPrice!.toStringAsFixed(2),
    'size': size,
    'brand': brand,
    'condition': condition,
  };
}
