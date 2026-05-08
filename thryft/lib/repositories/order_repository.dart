import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';
export 'package:thryft/repositories/listing_repository.dart' show NotAuthenticatedException;

/// This repository manages data fetching related to a user's order history and sales in the database.
/// It provides methods to retrieve items the user has purchased (orders) and items the user has sold.
/// Used by state management providers or directly by screens ( OrdersScreen,SoldItemsScreen) 
/// to display the user's transaction history.
class OrderRepository {
  final SupabaseClient _client;

  const OrderRepository(this._client);

  /// Fetches all products that  specified user has purchased.
  /// It filters the `products` table where the `buyer_id` matches the user's ID,
  /// and joins with the `profiles` table to include  seller's username.
  /// Returns a list of [Product] objects ordered by the date(newest first).
  Future<List<Product>> fetchOrders(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('buyer_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map(rowToProduct).toList();
  }

  /// Fetches  products that the specified user has successfully sold.
  /// It filters the `products` table where the `user_id` (seller) matches the user's ID
  /// and `is_sold` is true. Also joins with the `profiles` table to include  seller's username.
  /// Returns a list of [Product] objects ordered by creation date (newest first).
  Future<List<Product>> fetchSoldItems(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', true)
        .order('created_at', ascending: false);

    return (response as List).map(rowToProduct).toList();
  }

  /// Helper method to safely convert a raw JSON map from Supabase into  strongly typed [Product] object.
  /// Handles null safety, type casting, and mapping fields like `buyerId` and `orderStatus` 
  /// which are specific to order history contexts.
  /// Visible for testing to allow unit tests to verify the parsing logic.
  @visibleForTesting
  static Product rowToProduct(dynamic data) {
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
