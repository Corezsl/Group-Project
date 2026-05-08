import 'package:flutter_test/flutter_test.dart';

import '../helpers/supabase_test_client.dart';
import 'fr7_offer_test_helpers.dart';

void main() {
  // Skip the integration suite when .env.test has not been supplied via
  // --dart-define-from-file
  if (!hasTestCredentials) {
    test(
      'FR7 offer creation integration tests',
      () {},
      skip:
          'No Supabase credentials - run '
          'flutter test --dart-define-from-file=.env.test test/fr7_making_offer',
    );
    return;
  }

  final ctx = Fr7OfferTestContext('creation');

  setUpAll(ctx.setUpAll);
  tearDown(ctx.tearDown);
  tearDownAll(ctx.tearDownAll);

  // -------------------------------------------------------------------------
  // FR7 Partition 1 - Make valid offer (below listing price)
  // Inputs: offerPrice = 35, listingPrice = 50, buyerId = buyer1
  // Expected: offer saved, seller notified, confirmation path succeeds.
  // -------------------------------------------------------------------------
  group('FR7 #1 - make valid offer below listing price', () {
    test(
      'offer row and seller notification are inserted into database',
      () async {
        final listingId = await ctx.seedListing(
          name: 'FR7 Valid Offer',
          price: 50,
        );
        await ctx.signInBuyer(1);

        final error = await ctx.submitOfferThroughBackend(
          offerInput: '35',
          listingPrice: 50,
          listingId: listingId,
          listingTitle: 'FR7 Valid Offer',
          buyerId: ctx.buyer1Id,
          sellerId: ctx.sellerId,
        );

        expect(error, isNull);

        final offers = await ctx.offersForListing(listingId);
        expect(offers, hasLength(1));
        expect(offers.single['buyer_id'], ctx.buyer1Id);
        expect(offers.single['seller_id'], ctx.sellerId);
        expect(offers.single['listing_id'], listingId);
        expect((offers.single['offer_amount'] as num).toDouble(), 35);
        expect(offers.single['status'], 'pending');

        final notifications = await ctx.notificationsForListing(listingId);
        expect(notifications, hasLength(1));
        expect(notifications.single['user_id'], ctx.sellerId);
        expect(notifications.single['related_user_id'], ctx.buyer1Id);
        expect(notifications.single['notif_type'], 'offer_received');
        expect((notifications.single['offer_price'] as num).toDouble(), 35);
      },
    );
  });

  // -------------------------------------------------------------------------
  // FR7 Partition 4 - Multiple valid offers on same listing
  // Inputs: listingId = listing-7, offers from buyer1, buyer2, buyer3
  // Expected: all offers saved independently and seller gets one notification
  // for each offer.
  // -------------------------------------------------------------------------
  group('FR7 #4 - multiple valid offers on same listing', () {
    test(
      'stores independent offers and notifications without overwriting',
      () async {
        final listingId = await ctx.seedListing(
          name: 'FR7 Multiple Offers',
          price: 100,
        );

        await ctx.signInBuyer(1);
        expect(
          await ctx.submitOfferThroughBackend(
            offerInput: '31',
            listingPrice: 100,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            buyerId: ctx.buyer1Id,
            sellerId: ctx.sellerId,
          ),
          isNull,
        );

        await ctx.signInBuyer(2);
        expect(
          await ctx.submitOfferThroughBackend(
            offerInput: '32',
            listingPrice: 100,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            buyerId: ctx.buyer2Id,
            sellerId: ctx.sellerId,
          ),
          isNull,
        );

        await ctx.signInBuyer(3);
        expect(
          await ctx.submitOfferThroughBackend(
            offerInput: '33',
            listingPrice: 100,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            buyerId: ctx.buyer3Id,
            sellerId: ctx.sellerId,
          ),
          isNull,
        );

        final offers = await ctx.offersForListing(listingId);
        expect(offers, hasLength(3));
        expect(
          offers.map((row) => row['buyer_id']),
          containsAll([ctx.buyer1Id, ctx.buyer2Id, ctx.buyer3Id]),
        );
        expect(offers.map((row) => row['status']), everyElement('pending'));
        expect(
          offers.map((row) => (row['offer_amount'] as num).toDouble()),
          containsAll([31, 32, 33]),
        );

        final notifications = await ctx.notificationsForListing(listingId);
        expect(notifications, hasLength(3));
        expect(
          notifications.map((row) => row['related_user_id']),
          containsAll([ctx.buyer1Id, ctx.buyer2Id, ctx.buyer3Id]),
        );
        expect(
          notifications.map((row) => row['notif_type']),
          everyElement('offer_received'),
        );
      },
    );
  });
}
