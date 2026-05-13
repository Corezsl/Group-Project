import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// Exception thrown when the user is not logged in.
class NotLoggedInException implements Exception {
  const NotLoggedInException();
  @override
  String toString() =>
      'NotLoggedInException: user must be logged in to create a listing';
}

/// Repository that handles creating and updating product listings in Supabase.
class CreateListingRepository {
  final SupabaseClient _client;

  const CreateListingRepository(this._client);

  /// Uploads an image to Supabase storage and returns its public URL.
  Future<String> uploadImage(XFile image) async {
    final fileExt = image.name.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final bytes = await image.readAsBytes();

    await _client.storage
        .from('product-images')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

    return _client.storage.from('product-images').getPublicUrl(fileName);
  }

  /// Inserts a new product listing into the [products] table.
  /// Returns the generated product map.
  ///
  /// Throws [NotLoggedInException] if no user session is active.
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotLoggedInException();
    }

    data['user_id'] = user.id;

    final response = await _client
        .from('products')
        .insert(data)
        .select()
        .single();

    return response;
  }

  /// Updates an existing product listing in the [products] table.
  /// Handles price drop notifications if the price was lowered.
  ///
  /// Throws [NotLoggedInException] if no user session is active.
  Future<void> updateListing({
    required String listingId,
    required Map<String, dynamic> productData,
    double? oldPrice,
    required double newPrice,
    String? title,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const NotLoggedInException();
    }

    final bool isPriceDrop = oldPrice != null && newPrice < oldPrice;
    if (isPriceDrop) {
      productData['original_price'] = oldPrice;
    } else {
      productData['original_price'] = null;
    }

    await _client.from('products').update(productData).eq('id', listingId);

    // Send a price drop notification to everyone who wishlisted this item.
    if (isPriceDrop && title != null) {
      try {
        final wishlistEntries = await _client
            .from('wishlist')
            .select('user_id')
            .eq('listing_id', listingId);

        for (final entry in wishlistEntries as List) {
          final wishlisterId = entry['user_id']?.toString();
          if (wishlisterId != null && wishlisterId != user.id) {
            await NotificationProvider.insertNotification(
              userId: wishlisterId,
              type: NotificationType.priceDrop,
              content:
                  '"$title" dropped from £${oldPrice.toStringAsFixed(2)} to £${newPrice.toStringAsFixed(2)}!',
              listingId: listingId,
            );
          }
        }
      } catch (e) {
        debugPrint('Error sending price drop notifications: $e');
      }
    }
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
