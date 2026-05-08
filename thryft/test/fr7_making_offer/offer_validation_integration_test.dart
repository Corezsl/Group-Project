import 'package:flutter_test/flutter_test.dart';

import '../helpers/supabase_test_client.dart';
import 'fr7_offer_test_helpers.dart';

void main() {
  // Skip the integration suite when .env.test has not been supplied via
  // --dart-define-from-file, matching the FR4/FR5 integration test pattern.
  if (!hasTestCredentials) {
    test(
      'FR7 offer validation integration tests',
      () {},
      skip:
          'No Supabase credentials - run '
          'flutter test --dart-define-from-file=.env.test test/fr7_making_offer',
    );
    return;
  }

  final ctx = Fr7OfferTestContext('validation');

  setUpAll(ctx.setUpAll);
  tearDown(ctx.tearDown);
  tearDownAll(ctx.tearDownAll);

  // -------------------------------------------------------------------------
  // FR7 Partition 5 - Offer higher than listing price
  // Inputs: offerPrice = 120, listingPrice = 100
  // Expected: validation error returned and database insert is blocked.
  // -------------------------------------------------------------------------
  group('FR7 #5 - offer higher than listing price', () {
    test('rejects offer before writing offers or notifications', () async {
      final listingId = await ctx.seedListing(
        name: 'FR7 High Offer',
        price: 100,
      );

      final error = await ctx.submitOfferThroughBackend(
        offerInput: '120',
        listingPrice: 100,
        listingId: listingId,
        listingTitle: 'FR7 High Offer',
        buyerId: ctx.buyer1Id,
        sellerId: ctx.sellerId,
      );

      expect(error, 'Offer cannot exceed listing price');
      expect(await ctx.offersForListing(listingId), isEmpty);
      expect(await ctx.notificationsForListing(listingId), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // FR7 Partition 6 - Empty or null offer value
  // Inputs: offerPrice = null / empty string
  // Expected: required-field validation error and no database writes.
  // -------------------------------------------------------------------------
  group('FR7 #6 - empty or null offer value', () {
    test(
      'rejects null and empty offer values before database writes',
      () async {
        final listingId = await ctx.seedListing(
          name: 'FR7 Empty Offer',
          price: 100,
        );

        final nullError = await ctx.submitOfferThroughBackend(
          offerInput: null,
          listingPrice: 100,
          listingId: listingId,
          listingTitle: 'FR7 Empty Offer',
          buyerId: ctx.buyer1Id,
          sellerId: ctx.sellerId,
        );
        final emptyError = await ctx.submitOfferThroughBackend(
          offerInput: '',
          listingPrice: 100,
          listingId: listingId,
          listingTitle: 'FR7 Empty Offer',
          buyerId: ctx.buyer1Id,
          sellerId: ctx.sellerId,
        );

        expect(nullError, 'Offer amount required');
        expect(emptyError, 'Offer amount required');
        expect(await ctx.offersForListing(listingId), isEmpty);
        expect(await ctx.notificationsForListing(listingId), isEmpty);
      },
    );
  });

  // -------------------------------------------------------------------------
  // FR7 Partition 7 - Buyer offers on own listing
  // Inputs: buyerId = sellerId
  // Expected: operation denied, no offer row and no notification.
  // -------------------------------------------------------------------------
  group('FR7 #7 - buyer offers on own listing', () {
    test('blocks self-offer before database writes', () async {
      final listingId = await ctx.seedListing(
        name: 'FR7 Own Listing',
        price: 100,
      );

      final error = await ctx.submitOfferThroughBackend(
        offerInput: '35',
        listingPrice: 100,
        listingId: listingId,
        listingTitle: 'FR7 Own Listing',
        buyerId: ctx.sellerId,
        sellerId: ctx.sellerId,
      );

      expect(error, 'Buyer cannot offer on own listing');
      expect(await ctx.offersForListing(listingId), isEmpty);
      expect(await ctx.notificationsForListing(listingId), isEmpty);
    });
  });
}
