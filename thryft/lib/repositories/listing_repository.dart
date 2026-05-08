import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';

class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
  @override
  String toString() => 'NotAuthenticatedException: user is not logged in';
}

class ListingIsSoldException implements Exception {
  const ListingIsSoldException();
  @override
  String toString() => 'ListingIsSoldException: cannot delete a sold listing';
}

class ListingRepository {
  final SupabaseClient _client;

  const ListingRepository(this._client);

  Future<List<Product>> fetchActiveListings(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToProduct).toList();
  }

  Future<void> updateListing({
    required String id,
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const NotAuthenticatedException();
    }
    await _client.from('products').update(fields).eq('id', id);
  }

  Future<void> deleteListing({
    required String id,
    required String userId,
    required bool isSold,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const NotAuthenticatedException();
    }
    if (isSold) {
      throw const ListingIsSoldException();
    }
    await _client
        .from('products')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> markAsSold({
    required String id,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const NotAuthenticatedException();
    }
    await _client.rpc('purchase_listing', params: {
      'target_product_id': id,
    });
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
      description: data['description']?.toString(),
      imageUrl2: data['image_url_2']?.toString(),
      imageUrl3: data['image_url_3']?.toString(),
      imageUrl4: data['image_url_4']?.toString(),
      imageUrl5: data['image_url_5']?.toString(),
    );
  }
}
