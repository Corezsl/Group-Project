import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/product.dart';

/// Repository that handles fetching seller trust / profile info
/// from Supabase (profile, active listings, ratings, sold count).
class TrustInfoRepository {
  final SupabaseClient _client;

  const TrustInfoRepository(this._client);

  /// Fetches the profile row for [userId], or null if not found.
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('*, created_at')
        .eq('id', userId)
        .maybeSingle();

    return data;
  }

  /// Fetches active (unsold) products listed by [userId].
  Future<List<Product>> fetchActiveProducts(String userId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('user_id', userId)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map((data) {
      return Product(
        id: data['id'].toString(),
        name: data['name'].toString(),
        price: (data['price'] as num).toDouble(),
        originalPrice: data['original_price'] != null
            ? (data['original_price'] as num).toDouble()
            : null,
        size: data['size'].toString(),
        brand: data['brand'].toString(),
        condition: data['condition'].toString(),
        imageUrl: data['image_url']?.toString(),
        sellerId: userId,
        isSold: false,
        department: data['department']?.toString() ?? 'All',
        category: data['category']?.toString() ?? 'Other',
        material: data['material'].toString(),
        colour: data['colour'].toString(),
        description: data['description']?.toString(),
      );
    }).toList();
  }

  /// Fetches all ratings left for [sellerId], including product info
  /// and the buyer's username via the foreign key join.
  Future<List<Map<String, dynamic>>> fetchRatings(String sellerId) async {
    final response = await _client
        .from('ratings')
        .select(
          '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
        )
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Returns the number of sold products for [userId].
  Future<int> fetchSoldCount(String userId) async {
    final response = await _client
        .from('products')
        .select('id')
        .eq('user_id', userId)
        .eq('is_sold', true);

    return (response as List).length;
  }
}
