import 'package:flutter_test/flutter_test.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/offer_provider.dart';

import '../helpers/supabase_test_client.dart';
import 'fr7_offer_test_helpers.dart';

void main() {
  // Skip the integration suite when .env.test has not been supplied via
  // --dart-define-from-file
  if (!hasTestCredentials) {
    test(
      'FR7 offer response integration tests',
      () {},
      skip:
          'No Supabase credentials - run '
          'flutter test --dart-define-from-file=.env.test test/fr7_making_offer',
    );
    return;
  }

  final ctx = Fr7OfferTestContext('response');

  setUpAll(ctx.setUpAll);
  tearDown(ctx.tearDown);
  tearDownAll(ctx.tearDownAll);

  // -------------------------------------------------------------------------
  // FR7 Partition 2 - Seller accepts offer
  // Inputs: offerStatus = pending, sellerAction = accept
  // Expected: offer accepted, listing sold, buyer notified.
  // -------------------------------------------------------------------------
  group('FR7 #2 - seller accepts offer', () {
    test(
      'updates offer status, product sale fields, and buyer notification',
      () async {
        final listingId = await ctx.seedListing(
          name: 'FR7 Accept Offer',
          price: 80,
        );
        await ctx.signInBuyer(1);
        await ctx.submitOfferThroughBackend(
          offerInput: '60',
          listingPrice: 80,
          listingId: listingId,
          listingTitle: 'FR7 Accept Offer',
          buyerId: ctx.buyer1Id,
          sellerId: ctx.sellerId,
        );

        final sellerNotification = (await ctx.notificationsForListing(
          listingId,
        )).single;

        await ctx.signInSeller();
        final provider = NotificationProvider();
        await provider.acceptOffer(AppNotification.fromMap(sellerNotification));

        final offer = (await ctx.offersForListing(listingId)).single;
        expect(offer['status'], 'accepted');

        final product = await ctx.serviceClient
            .from('products')
            .select('is_sold, buyer_id, order_status, price')
            .eq('id', listingId)
            .single();
        expect(product['is_sold'], isTrue);
        expect(product['buyer_id'], ctx.buyer1Id);
        expect(product['order_status'], 'pending');
        expect((product['price'] as num).toDouble(), 60);

        final notifications = await ctx.notificationsForListing(listingId);
        expect(
          notifications.where((row) => row['notif_type'] == 'offer_received'),
          isEmpty,
        );
        expect(
          notifications.where(
            (row) =>
                row['user_id'] == ctx.buyer1Id &&
                row['notif_type'] == 'offer_accepted',
          ),
          hasLength(1),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // FR7 Partition 3 - Seller rejects offer
  // Inputs: offerStatus = pending, sellerAction = reject
  // Expected: offer declined, listing remains unsold, buyer notified.
  // -------------------------------------------------------------------------
  group('FR7 #3 - seller rejects offer', () {
    test(
      'updates offer status to declined and sends rejection notification',
      () async {
        final listingId = await ctx.seedListing(
          name: 'FR7 Reject Offer',
          price: 90,
        );
        await ctx.signInBuyer(2);
        await ctx.submitOfferThroughBackend(
          offerInput: '40',
          listingPrice: 90,
          listingId: listingId,
          listingTitle: 'FR7 Reject Offer',
          buyerId: ctx.buyer2Id,
          sellerId: ctx.sellerId,
        );

        final sellerNotification = (await ctx.notificationsForListing(
          listingId,
        )).single;

        await ctx.signInSeller();
        final provider = NotificationProvider();
        await provider.declineOffer(
          AppNotification.fromMap(sellerNotification),
        );

        final offer = (await ctx.offersForListing(listingId)).single;
        expect(offer['status'], 'declined');

        final product = await ctx.serviceClient
            .from('products')
            .select('is_sold, buyer_id')
            .eq('id', listingId)
            .single();
        expect(product['is_sold'], isFalse);
        expect(product['buyer_id'], isNull);

        final notifications = await ctx.notificationsForListing(listingId);
        expect(
          notifications.where((row) => row['notif_type'] == 'offer_received'),
          isEmpty,
        );
        expect(
          notifications.where(
            (row) =>
                row['user_id'] == ctx.buyer2Id &&
                row['notif_type'] == 'offer_declined',
          ),
          hasLength(1),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // FR7 Partition 8 - Seller responds to non-existent offer
  // Inputs: offerId = invalid-offer-99
  // Expected: no exception escapes and no listing/offer data is corrupted.
  // -------------------------------------------------------------------------
  group('FR7 #8 - seller responds to non-existent offer', () {
    test('invalid offer id is rejected and leaves data unchanged', () async {
      final listingId = await ctx.seedListing(
        name: 'FR7 Nonexistent Offer',
        price: 100,
      );
      await ctx.signInSeller();

      final updated = await OfferProvider.updateOfferStatusById(
        offerId: 'invalid-offer-99',
        status: 'accepted',
      );

      expect(updated, isFalse);

      final product = await ctx.serviceClient
          .from('products')
          .select('is_sold, buyer_id, price')
          .eq('id', listingId)
          .single();
      expect(product['is_sold'], isFalse);
      expect(product['buyer_id'], isNull);
      expect((product['price'] as num).toDouble(), 100);
      expect(await ctx.offersForListing(listingId), isEmpty);
      expect(await ctx.notificationsForListing(listingId), isEmpty);
    });
  });
}
