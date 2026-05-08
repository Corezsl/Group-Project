import 'package:flutter_test/flutter_test.dart';

// Simple validator functions mirroring UI/backend rules for offers.
String? validateOfferAmount(double? offer, double listingPrice) {
  if (offer == null) return 'Offer amount required';
  if (offer <= 0) return 'Offer amount required';
  if (offer > listingPrice) return 'Offer cannot exceed listing price';
  return null;
}

String? validateBuyerNotSeller(String buyerId, String sellerId) {
  if (buyerId == sellerId) return 'Buyer cannot offer on own listing';
  return null;
}

void main() {
  group('FR7 Partition — Validators', () {
    test('empty or null offer value returns required error', () {
      expect(validateOfferAmount(null, 100), equals('Offer amount required'));
      expect(validateOfferAmount(0, 100), equals('Offer amount required'));
    });

    test('offer higher than listing price is rejected', () {
      expect(validateOfferAmount(120, 100), equals('Offer cannot exceed listing price'));
    });

    test('valid offer returns null', () {
      expect(validateOfferAmount(50, 100), isNull);
    });

    test('buyer offering on own listing is blocked', () {
      expect(validateBuyerNotSeller('seller-1', 'seller-1'), equals('Buyer cannot offer on own listing'));
      expect(validateBuyerNotSeller('buyer-1', 'seller-1'), isNull);
    });
  });
}
