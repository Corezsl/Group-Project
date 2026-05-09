import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';

/// This repository manages data operations related to a user's listings in the Supabase database.
/// It provides methods to fetch a user's active listings, update their details, delete them, 
/// and mark them as sold. 
/// 
/// Used primarily by state management providers or directly by screens 
/// (like MyListingsScreen or EditListingScreen) to interact with the backend `products` table.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
  @override
  String toString() => 'NotAuthenticatedException: user is not logged in';
}

/// Thrown when attempting to delete a listing that has already been marked as sold.
/// Sold listings must be preserved for order history and buyer/seller records.
class ListingIsSoldException implements Exception {
  const ListingIsSoldException();
  @override
  String toString() => 'ListingIsSoldException: cannot delete a sold listing';
}

class ListingRepository {
  final SupabaseClient _client;

  const ListingRepository(this._client);

  /// Fetches all active (unsold) listings created by a specific user.
  /// Joins the `products` table with the `profiles` table to include the seller's username.
  /// Returns a list of [Product] objects ordered by creation date (newest first).
  Future<List<Product>> fetchActiveListings(String userId) async {
    final response = await _client
        .from('products')
        .select('*, profiles(username)')
        .eq('user_id', userId)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToProduct).toList();
  }

  /// Updates specific fields of an existing listing in the database.
  /// Requires the user to be logged in. Throws [NotAuthenticatedException] if not.
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

  /// Deletes a listing from the database permanently.
  /// Prevents deletion if the item is already sold ([ListingIsSoldException]).
  /// Requires the user to be logged in ([NotAuthenticatedException]).
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

  /// Marks a specific listing as sold by invoking a Supabase RPC (Remote Procedure Call) 
  /// named `purchase_listing`.
  /// Requires the user to be logged in. Throws [NotAuthenticatedException] if not.
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

  /// Helper method to safely convert a raw JSON map from Supabase into a strongly typed [Product] object.
  /// Handles null safety, type casting, and providing default values for missing fields.
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
