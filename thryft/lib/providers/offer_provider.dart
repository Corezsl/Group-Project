import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/offer_model.dart';

class OfferAmountRequiredException implements Exception {
  const OfferAmountRequiredException();

  @override
  String toString() => 'OfferAmountRequiredException';
}

class OfferExceedsListingPriceException implements Exception {
  const OfferExceedsListingPriceException();

  @override
  String toString() => 'OfferExceedsListingPriceException';
}

class SelfOfferException implements Exception {
  const SelfOfferException();

  @override
  String toString() => 'SelfOfferException';
}

class OfferProvider extends ChangeNotifier {
  List<Offer> _offers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Offer> get offers => List.unmodifiable(_offers);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _offers.where((o) => o.isPending).length;

  OfferProvider() {
    _init();
  }

  void _init() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        fetchMyOffers();
      } else {
        _offers.clear();
        notifyListeners();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      fetchMyOffers();
    }
  }

  Future<void> fetchMyOffers() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('buyer_id', userId)
          .order('created_at', ascending: false);

      _offers = (response as List)
          .map((data) => Offer.fromMap(data as Map<String, dynamic>))
          .toList();
      _hasError = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new offer record in the database.
  /// Returns the new offer_id, or null on failure.
  static void validateOfferOrThrow({
    required double? offerAmount,
    required double listingPrice,
    required String buyerId,
    required String sellerId,
  }) {
    if (offerAmount == null || offerAmount < 0.01) {
      throw const OfferAmountRequiredException();
    }
    if (offerAmount >= listingPrice) {
      throw const OfferExceedsListingPriceException();
    }
    if (buyerId == sellerId) {
      throw const SelfOfferException();
    }
  }

  static Future<int?> createOffer({
    required String buyerId,
    required String sellerId,
    required String listingId,
    required double offerAmount,
    String? listingTitle,
    String? listingImageUrl,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .insert({
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'listing_id': listingId,
            'offer_amount': offerAmount,
            if (listingTitle != null) 'listing_title': listingTitle,
            if (listingImageUrl != null) 'listing_image_url': listingImageUrl,
            'status': 'pending',
          })
          .select('offer_id')
          .single();
      return (response['offer_id'] as num).toInt();
    } catch (e) {
      debugPrint('Error creating offer: $e');
      return null;
    }
  }

  /// Checks whether the current user already has a pending offer on a listing.
  static Future<bool> hasPendingOffer({
    required String buyerId,
    required String listingId,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('offers')
          .select('offer_id')
          .eq('buyer_id', buyerId)
          .eq('listing_id', listingId)
          .eq('status', 'pending');
      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending offer: $e');
      return false;
    }
  }

  /// Updates offer status (called by NotificationProvider when seller decides).
  static Future<void> updateOfferStatus({
    required String listingId,
    required String buyerId,
    required String status,
  }) async {
    try {
      await Supabase.instance.client
          .from('offers')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('listing_id', listingId)
          .eq('buyer_id', buyerId)
          .eq('status', 'pending');
    } catch (e) {
      debugPrint('Error updating offer status: $e');
    }
  }

  /// Updates offer status by offer id. Returns false when the id is invalid,
  /// does not exist, or does not point to a pending offer.
  static Future<bool> updateOfferStatusById({
    required String offerId,
    required String status,
  }) async {
    final parsedOfferId = int.tryParse(offerId);
    if (parsedOfferId == null) return false;

    try {
      final response = await Supabase.instance.client
          .from('offers')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('offer_id', parsedOfferId)
          .eq('status', 'pending')
          .select('offer_id')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error updating offer status by id: $e');
      return false;
    }
  }
}
