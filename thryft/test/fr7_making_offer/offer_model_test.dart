import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/offer_model.dart';

Map<String, dynamic> _offerRow({
  int offerId = 1,
  String buyerId = 'buyer-1',
  String sellerId = 'seller-1',
  String listingId = 'listing-1',
  String? listingTitle = 'Vintage Jacket',
  String? listingImageUrl = 'https://example.com/image.jpg',
  double offerAmount = 35,
  String status = 'pending',
  String createdAt = '2026-01-01T00:00:00.000Z',
}) =>
    {
      'offer_id': offerId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'listing_id': listingId,
      'listing_title': listingTitle,
      'listing_image_url': listingImageUrl,
      'offer_amount': offerAmount,
      'status': status,
      'created_at': createdAt,
    };

void main() {
  group('FR7 - offer model parsing', () {
    test('fromMap parses a valid pending offer', () {
      final offer = Offer.fromMap(_offerRow());

      expect(offer.offerId, equals(1));
      expect(offer.buyerId, equals('buyer-1'));
      expect(offer.sellerId, equals('seller-1'));
      expect(offer.listingId, equals('listing-1'));
      expect(offer.offerAmount, equals(35.0));
      expect(offer.status, equals('pending'));
      expect(offer.isPending, isTrue);
    });

    test('accepted status toggles status helpers correctly', () {
      final offer = Offer.fromMap(_offerRow(status: 'accepted'));

      expect(offer.isAccepted, isTrue);
      expect(offer.isPending, isFalse);
      expect(offer.isDeclined, isFalse);
    });

    test('declined status toggles status helpers correctly', () {
      final offer = Offer.fromMap(_offerRow(status: 'declined'));

      expect(offer.isDeclined, isTrue);
      expect(offer.isPending, isFalse);
      expect(offer.isAccepted, isFalse);
    });

    test('missing fields fallback to defaults', () {
      final offer = Offer.fromMap({});

      expect(offer.offerId, equals(0));
      expect(offer.buyerId, equals(''));
      expect(offer.sellerId, equals(''));
      expect(offer.listingId, equals(''));
      expect(offer.offerAmount, equals(0));
      expect(offer.status, equals('pending'));
    });
  });
}
