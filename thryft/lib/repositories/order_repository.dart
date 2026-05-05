import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
export 'package:thryft/repositories/listing_repository.dart' show NotAuthenticatedException;

class OrderRepository {
  final SupabaseClient _client;

  const OrderRepository(this._client);

  Future<List<Product>> fetchOrders(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToProduct).toList();
  }

  Future<List<Product>> fetchSoldItems(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', true)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToProduct).toList();
  }

  static Product _rowToProduct(dynamic data) {
    return Product(
      id: data['id'].toString(),
      name: data['name']?.toString() ?? '',
      price: (data['price'] as num).toDouble(),
      originalPrice: data['original_price'] != null
          ? (data['original_price'] as num).toDouble()
          : null,
      size: data['size']?.toString() ?? '',
      brand: data['brand']?.toString() ?? '',
      condition: data['condition']?.toString() ?? '',
      imageUrl: data['image_url']?.toString(),
      sellerId: data['user_id']?.toString(),
      sellerName: data['profiles'] != null
          ? data['profiles']['username']?.toString()
          : null,
      isSold: data['is_sold'] == true,
      department: data['department']?.toString() ?? 'All',
      category: data['category']?.toString() ?? 'Other',
      material: data['material']?.toString() ?? '',
      colour: data['colour']?.toString() ?? '',
      buyerId: data['buyer_id']?.toString(),
      orderStatus: data['order_status']?.toString(),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      description: data['description']?.toString(),
    );
  }
}
