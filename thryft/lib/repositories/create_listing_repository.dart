import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when the user is not logged in.
class NotLoggedInException implements Exception {
  const NotLoggedInException();
  @override
  String toString() => 'NotLoggedInException: user must be logged in to create a listing';
}

/// Repository that handles creating product listings in Supabase.
class CreateListingRepository {
  final SupabaseClient _client;

  const CreateListingRepository(this._client);

  /// Inserts a new product listing into the [products] table.
  /// Returns the generated product id.
  ///
  /// Throws [NotLoggedInException] if no user session is active.
  Future<String> createListing(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotLoggedInException();
    }

    // Ensure user_id is set to the current user
    data['user_id'] = user.id;

    final response = await _client
        .from('products')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Returns true if the user has at least one payment method on file.
  Future<bool> hasPaymentMethod(String userId) async {
    final row = await _client
        .from('payment_methods')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return row != null;
  }

  /// Returns true if the user has at least one address on file.
  Future<bool> hasAddress(String userId) async {
    final row = await _client
        .from('address')
        .select('address_id')
        .eq('user_id', userId)
        .maybeSingle();

    return row != null;
  }
}
