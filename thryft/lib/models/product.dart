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
  final String? description;

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
    this.description,
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
      colour: map['colour'] ?? 'Not Provided',
      category: map['category'] ?? 'Unknown',
      department:  map['department'] ?? 'Unknown',
      material: map['material'] ?? 'Not Provided',
      description: map['description']
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
    if (imageUrl != null) 'imageUrl': imageUrl!,
    if (sellerId != null) 'sellerId': sellerId!,
    if (sellerName != null) 'sellerName': sellerName!,
    'is_sold': isSold.toString(),
    'category': category,
    'department': department,
    'material': material,
    'colour': colour,
    if (description != null) 'description': description!,
  };
}