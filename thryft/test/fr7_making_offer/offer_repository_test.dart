import 'package:flutter_test/flutter_test.dart';

class OfferValidationException implements Exception {
  final String message;
  OfferValidationException(this.message);

  @override
  String toString() => 'OfferValidationException: $message';
}

class OfferNotFoundException implements Exception {
  final String message;
  OfferNotFoundException(this.message);

  @override
  String toString() => 'OfferNotFoundException: $message';
}

class _OfferRecord {
  final int offerId;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double offerPrice;
  String status = 'pending';

  _OfferRecord({
    required this.offerId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.offerPrice,
  });
}

class _ListingRecord {
  final String id;
  final double listingPrice;
  bool isSold = false;

  _ListingRecord({
    required this.id,
    required this.listingPrice,
  });
}

class _NotificationRecord {
  final String userId;
  final String type;
  final String listingId;
  final int offerId;

  _NotificationRecord({
    required this.userId,
    required this.type,
    required this.listingId,
    required this.offerId,
  });
}

class _OfferRepository {
  final Map<String, _ListingRecord> listings;
  final Map<int, _OfferRecord> offers = {};
  final List<_NotificationRecord> notifications = [];

  int _offerSequence = 1;

  _OfferRepository(this.listings);

  int makeOffer({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required double? offerPrice,
  }) {
    final listing = listings[listingId];
    if (listing == null) {
      throw OfferValidationException('Listing not found');
    }

    if (offerPrice == null || offerPrice <= 0) {
      throw OfferValidationException('Offer amount required');
    }

    if (offerPrice > listing.listingPrice) {
      throw OfferValidationException('Offer cannot exceed listing price');
    }

    if (buyerId == sellerId) {
      throw OfferValidationException('Buyer cannot offer on own listing');
    }

    final offer = _OfferRecord(
      offerId: _offerSequence++,
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      offerPrice: offerPrice,
    );

    offers[offer.offerId] = offer;

    notifications.add(
      _NotificationRecord(
        userId: sellerId,
        type: 'offer_received',
        listingId: listingId,
        offerId: offer.offerId,
      ),
    );

    return offer.offerId;
  }

  void respondToOffer({
    required int offerId,
    required String sellerAction,
  }) {
    final offer = offers[offerId];
    if (offer == null || offer.status != 'pending') {
      throw OfferNotFoundException('Pending offer not found');
    }

    final listing = listings[offer.listingId];
    if (listing == null) {
      throw OfferValidationException('Listing not found');
    }

    if (sellerAction == 'accept') {
      offer.status = 'accepted';
      listing.isSold = true;
      notifications.add(
        _NotificationRecord(
          userId: offer.buyerId,
          type: 'offer_accepted',
          listingId: offer.listingId,
          offerId: offer.offerId,
        ),
      );
      return;
    }

    if (sellerAction == 'reject') {
      offer.status = 'rejected';
      notifications.add(
        _NotificationRecord(
          userId: offer.buyerId,
          type: 'offer_rejected',
          listingId: offer.listingId,
          offerId: offer.offerId,
        ),
      );
      return;
    }

    throw OfferValidationException('Unknown seller action');
  }
}

void main() {
  group('FR7: making offer for listing', () {
    late _OfferRepository repo;

    setUp(() {
      repo = _OfferRepository({
        'listing-7': _ListingRecord(id: 'listing-7', listingPrice: 50),
        'listing-100': _ListingRecord(id: 'listing-100', listingPrice: 100),
      });
    });

    test('Make valid offer (below listing price)', () {
      final offerId = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-123',
        sellerId: 'seller-123',
        offerPrice: 35,
      );

      expect(repo.offers[offerId], isNotNull);
      expect(repo.offers[offerId]!.status, equals('pending'));
      expect(
        repo.notifications
            .where((n) => n.userId == 'seller-123' && n.type == 'offer_received')
            .length,
        equals(1),
      );
    });

    test('Seller accepts offer', () {
      final offerId = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-123',
        sellerId: 'seller-123',
        offerPrice: 35,
      );

      repo.respondToOffer(offerId: offerId, sellerAction: 'accept');

      expect(repo.offers[offerId]!.status, equals('accepted'));
      expect(repo.listings['listing-7']!.isSold, isTrue);
      expect(
        repo.notifications
            .where((n) => n.userId == 'buyer-123' && n.type == 'offer_accepted')
            .length,
        equals(1),
      );
    });

    test('Seller rejects offer', () {
      final offerId = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-123',
        sellerId: 'seller-123',
        offerPrice: 35,
      );

      repo.respondToOffer(offerId: offerId, sellerAction: 'reject');

      expect(repo.offers[offerId]!.status, equals('rejected'));
      expect(repo.listings['listing-7']!.isSold, isFalse);
      expect(
        repo.notifications
            .where((n) => n.userId == 'buyer-123' && n.type == 'offer_rejected')
            .length,
        equals(1),
      );
    });

    test('Multiple valid offers on same listing', () {
      final offer1 = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-1',
        sellerId: 'seller-123',
        offerPrice: 30,
      );
      final offer2 = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-2',
        sellerId: 'seller-123',
        offerPrice: 31,
      );
      final offer3 = repo.makeOffer(
        listingId: 'listing-7',
        buyerId: 'buyer-3',
        sellerId: 'seller-123',
        offerPrice: 32,
      );

      expect(repo.offers[offer1]!.status, equals('pending'));
      expect(repo.offers[offer2]!.status, equals('pending'));
      expect(repo.offers[offer3]!.status, equals('pending'));
      expect(
        repo.notifications
            .where((n) => n.userId == 'seller-123' && n.type == 'offer_received')
            .length,
        equals(3),
      );
    });

    test('Offer higher than listing price', () {
      expect(
        () => repo.makeOffer(
          listingId: 'listing-100',
          buyerId: 'buyer-123',
          sellerId: 'seller-123',
          offerPrice: 120,
        ),
        throwsA(isA<OfferValidationException>()),
      );

      expect(repo.offers, isEmpty);
      expect(repo.notifications, isEmpty);
    });

    test('Empty or null offer value', () {
      expect(
        () => repo.makeOffer(
          listingId: 'listing-100',
          buyerId: 'buyer-123',
          sellerId: 'seller-123',
          offerPrice: null,
        ),
        throwsA(isA<OfferValidationException>()),
      );

      expect(repo.offers, isEmpty);
      expect(repo.notifications, isEmpty);
    });

    test('Buyer offers on own listing', () {
      expect(
        () => repo.makeOffer(
          listingId: 'listing-100',
          buyerId: 'seller-123',
          sellerId: 'seller-123',
          offerPrice: 80,
        ),
        throwsA(isA<OfferValidationException>()),
      );

      expect(repo.offers, isEmpty);
      expect(repo.notifications, isEmpty);
    });

    test('Seller responds to non-existent offer', () {
      expect(
        () => repo.respondToOffer(offerId: 99, sellerAction: 'accept'),
        throwsA(isA<OfferNotFoundException>()),
      );

      expect(repo.offers, isEmpty);
      expect(repo.notifications, isEmpty);
      expect(repo.listings['listing-7']!.isSold, isFalse);
    });
  });
}
