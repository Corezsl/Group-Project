import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/offer_model.dart';

Map<String, dynamic> _offerRow({
  int offerId = 1,
  String buyerId = 'buyer-1',
  String sellerId = 'seller-1',
  String listingId = 'listing-1',
  double offerAmount = 35,
  String status = 'pending',
  String createdAt = '2026-01-01T00:00:00.000Z',
}) =>
    {
      'offer_id': offerId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'listing_id': listingId,
      'offer_amount': offerAmount,
      'status': status,
      'created_at': createdAt,
    };

void main() {
  group('FR7 Partition 1 — Offer model', () {
    test('fromMap parses pending offer correctly', () {
      final offer = Offer.fromMap(_offerRow());

      expect(offer.offerId, equals(1));
      expect(offer.buyerId, equals('buyer-1'));
      expect(offer.sellerId, equals('seller-1'));
      expect(offer.listingId, equals('listing-1'));
      expect(offer.offerAmount, equals(35.0));
      expect(offer.status, equals('pending'));
      expect(offer.isPending, isTrue);
    });

    test('status helpers reflect accepted/declined states', () {
      final accepted = Offer.fromMap(_offerRow(status: 'accepted'));
      final declined = Offer.fromMap(_offerRow(status: 'declined'));

      expect(accepted.isAccepted, isTrue);
      expect(declined.isDeclined, isTrue);
    });

    test('fromMap handles missing fields with safe defaults', () {
      final offer = Offer.fromMap({});

      expect(offer.offerId, equals(0));
      expect(offer.offerAmount, equals(0.0));
      expect(offer.status, equals('pending'));
    });
  });
}
