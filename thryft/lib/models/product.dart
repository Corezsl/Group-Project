class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final double? originalPrice;
  final String size;
  final String brand;
  final String condition;
  final DateTime? createdAt; // used for sorting lists
  final String? sellerId;
  final String? sellerName;
  final bool isSold;
  final String category;
  final String department;
  final String material;
  final String colour;
  final String? buyerId;
  final String? orderStatus; // 'pending', 'shipped', 'delivered'
  final String? description;
  final String? imageUrl2;
  final String? imageUrl3;
  final String? imageUrl4;
  final String? imageUrl5;

  const Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.size,
    required this.brand,
    required this.condition,
    this.createdAt,
    this.sellerId,
    this.sellerName,
    this.isSold = false,
    required this.department,
    required this.category,
    required this.material,
    required this.colour,
    this.buyerId,
    this.orderStatus,
    this.description,
    this.imageUrl2,
    this.imageUrl3,
    this.imageUrl4,
    this.imageUrl5,
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
    if (imageUrl != null) 'imageUrl': imageUrl!,
    if (sellerId != null) 'sellerId': sellerId!,
    if (sellerName != null) 'sellerName': sellerName!,
    'is_sold': isSold.toString(),
    'category': category,
    'department': department,
    'material': material,
    'colour': colour,
    if (description != null) 'description': description!,
    if (imageUrl2 != null) 'image_url_2': imageUrl2!,
    if (imageUrl3 != null) 'image_url_3': imageUrl3!,
    if (imageUrl4 != null) 'image_url_4': imageUrl4!,
    if (imageUrl5 != null) 'image_url_5': imageUrl5!,
  };
}