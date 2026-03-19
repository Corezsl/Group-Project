class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final double? originalPrice;
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

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? 'Unknown Item',
      imageUrl: map['image_url'],
      price: (map['price'] ?? 0).toDouble(),
      originalPrice: map['original_price'] != null 
          ? (map['original_price'] as num).toDouble() 
          : null,
      size: map['size'] ?? 'N/A',
      brand: map['brand'] ?? 'Unbranded',
      condition: map['condition'] ?? 'Unknown',
    );
  }

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