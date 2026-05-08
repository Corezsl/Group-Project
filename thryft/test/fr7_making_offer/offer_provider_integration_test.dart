import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/offer_provider.dart';

import '../helpers/seed_helper.dart';
import '../helpers/supabase_test_client.dart';

const _password = 'Thryft!test99';

Future<String> _ensureSignedInTestUser(
  SupabaseClient client,
  SupabaseClient serviceClient,
  String email,
  String username,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: _password,
    );
    return res.user!.id;
  } on AuthException {
    final created = await serviceClient.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: _password,
        emailConfirm: true,
        userMetadata: {'username': username},
      ),
    );
    final createdUser = created.user;
    if (createdUser == null) {
      throw StateError('Could not create test auth user $email');
    }

    await serviceClient.from('profiles').upsert({
      'id': createdUser.id,
      'username': username,
      'rating': 0.0,
      'rating_count': 0,
    });

    final res = await client.auth.signInWithPassword(
      email: email,
      password: _password,
    );
    return res.user!.id;
  }
}

Future<void> _signInBuyer(
  SupabaseClient client,
  SupabaseClient serviceClient,
  int buyerNumber,
) async {
  await _ensureSignedInTestUser(
    client,
    serviceClient,
    'fr7.$runId.buyer$buyerNumber@thryft-test.local',
    'fr7_${runId}_buyer_$buyerNumber',
  );
}

Future<void> _signInSeller(
  SupabaseClient client,
  SupabaseClient serviceClient,
) async {
  await _ensureSignedInTestUser(
    client,
    serviceClient,
    'fr7.$runId.seller@thryft-test.local',
    'fr7_${runId}_seller',
  );
}

Future<String?> _submitOfferLikeProductDetail({
  required String buyerId,
  required String sellerId,
  required String listingId,
  required String listingTitle,
  required double listingPrice,
  required double? offerPrice,
}) async {
  if (offerPrice == null || offerPrice < 0.01) {
    return 'Offer amount required';
  }
  if (offerPrice >= listingPrice) {
    return 'Offer cannot exceed listing price';
  }
  if (buyerId == sellerId) {
    return 'Buyer cannot offer on own listing';
  }

  final alreadyPending = await OfferProvider.hasPendingOffer(
    buyerId: buyerId,
    listingId: listingId,
  );
  if (alreadyPending) return 'Pending offer already exists';

  final offerId = await OfferProvider.createOffer(
    buyerId: buyerId,
    sellerId: sellerId,
    listingId: listingId,
    offerAmount: offerPrice,
    listingTitle: listingTitle,
  );
  if (offerId == null) return 'Offer could not be saved';

  await NotificationProvider.insertNotification(
    userId: sellerId,
    type: NotificationType.offerReceived,
    content:
        'Buyer offered GBP ${offerPrice.toStringAsFixed(2)} for "$listingTitle"',
    listingId: listingId,
    relatedUserId: buyerId,
    offerPrice: offerPrice,
  );

  return null;
}

Future<List<dynamic>> _offersForListing(
  SupabaseClient client,
  String listingId,
) {
  return client
      .from('offers')
      .select()
      .eq('listing_id', listingId)
      .order('offer_id', ascending: true);
}

Future<List<dynamic>> _notificationsForListing(
  SupabaseClient client,
  String listingId,
) {
  return client
      .from('notification')
      .select()
      .eq('listing_id', listingId)
      .order('notification_id', ascending: true);
}

void main() {
  if (!hasTestCredentials) {
    test(
      'FR7 integration tests',
      () {},
      skip:
          'No Supabase credentials - run '
          'flutter test --dart-define-from-file=.env.test test/fr7_making_offer',
    );
    return;
  }

  late SupabaseClient client;
  late SupabaseClient serviceClient;
  late String sellerId;
  late String buyer1Id;
  late String buyer2Id;
  late String buyer3Id;
  final listingIds = <String>[];

  Future<String> seedListing({
    required String name,
    double price = 100,
    bool isSold = false,
  }) async {
    await _signInSeller(client, serviceClient);
    final id = await seedProduct(
      client,
      sellerId: sellerId,
      name: name,
      price: price,
      isSold: isSold,
    );
    listingIds.add(id);
    return id;
  }

  setUpAll(() async {
    client = await getTestClient();
    serviceClient = getServiceClient();

    sellerId = await _ensureSignedInTestUser(
      client,
      serviceClient,
      'fr7.$runId.seller@thryft-test.local',
      'fr7_${runId}_seller',
    );
    buyer1Id = await _ensureSignedInTestUser(
      client,
      serviceClient,
      'fr7.$runId.buyer1@thryft-test.local',
      'fr7_${runId}_buyer_1',
    );
    buyer2Id = await _ensureSignedInTestUser(
      client,
      serviceClient,
      'fr7.$runId.buyer2@thryft-test.local',
      'fr7_${runId}_buyer_2',
    );
    buyer3Id = await _ensureSignedInTestUser(
      client,
      serviceClient,
      'fr7.$runId.buyer3@thryft-test.local',
      'fr7_${runId}_buyer_3',
    );
  });

  tearDown(() async {
    if (listingIds.isEmpty) return;
    await serviceClient
        .from('notification')
        .delete()
        .inFilter('listing_id', List<String>.from(listingIds));
    await serviceClient
        .from('offers')
        .delete()
        .inFilter('listing_id', List<String>.from(listingIds));
    await serviceClient
        .from('products')
        .delete()
        .inFilter('id', List<String>.from(listingIds));
    listingIds.clear();
  });

  tearDownAll(() async {
    await client.auth.signOut();
  });

  group('FR7 integration - making offers through backend and database', () {
    test(
      'valid offer is inserted and seller receives a notification',
      () async {
        final listingId = await seedListing(name: 'FR7 Valid Offer', price: 50);
        await _signInBuyer(client, serviceClient, 1);

        final error = await _submitOfferLikeProductDetail(
          buyerId: buyer1Id,
          sellerId: sellerId,
          listingId: listingId,
          listingTitle: 'FR7 Valid Offer',
          listingPrice: 50,
          offerPrice: 35,
        );

        expect(error, isNull);

        final offers = await _offersForListing(serviceClient, listingId);
        expect(offers, hasLength(1));
        expect(offers.single['buyer_id'], buyer1Id);
        expect(offers.single['seller_id'], sellerId);
        expect((offers.single['offer_amount'] as num).toDouble(), 35);
        expect(offers.single['status'], 'pending');

        final notifications = await _notificationsForListing(
          serviceClient,
          listingId,
        );
        expect(notifications, hasLength(1));
        expect(notifications.single['user_id'], sellerId);
        expect(notifications.single['related_user_id'], buyer1Id);
        expect(notifications.single['notif_type'], 'offer_received');
        expect((notifications.single['offer_price'] as num).toDouble(), 35);
      },
    );

    test(
      'multiple buyers can make independent offers on one listing',
      () async {
        final listingId = await seedListing(name: 'FR7 Multiple Offers');

        await _signInBuyer(client, serviceClient, 1);
        expect(
          await _submitOfferLikeProductDetail(
            buyerId: buyer1Id,
            sellerId: sellerId,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            listingPrice: 100,
            offerPrice: 31,
          ),
          isNull,
        );

        await _signInBuyer(client, serviceClient, 2);
        expect(
          await _submitOfferLikeProductDetail(
            buyerId: buyer2Id,
            sellerId: sellerId,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            listingPrice: 100,
            offerPrice: 32,
          ),
          isNull,
        );

        await _signInBuyer(client, serviceClient, 3);
        expect(
          await _submitOfferLikeProductDetail(
            buyerId: buyer3Id,
            sellerId: sellerId,
            listingId: listingId,
            listingTitle: 'FR7 Multiple Offers',
            listingPrice: 100,
            offerPrice: 33,
          ),
          isNull,
        );

        final offers = await _offersForListing(serviceClient, listingId);
        expect(offers, hasLength(3));
        expect(
          offers.map((row) => row['buyer_id']),
          containsAll([buyer1Id, buyer2Id, buyer3Id]),
        );
        expect(offers.map((row) => row['status']), everyElement('pending'));

        final notifications = await _notificationsForListing(
          serviceClient,
          listingId,
        );
        expect(notifications, hasLength(3));
        expect(
          notifications.map((row) => row['related_user_id']),
          containsAll([buyer1Id, buyer2Id, buyer3Id]),
        );
      },
    );

    test(
      'seller accepts offer: product is sold, offer accepted, buyer notified',
      () async {
        final listingId = await seedListing(
          name: 'FR7 Accept Offer',
          price: 80,
        );
        await _signInBuyer(client, serviceClient, 1);
        await _submitOfferLikeProductDetail(
          buyerId: buyer1Id,
          sellerId: sellerId,
          listingId: listingId,
          listingTitle: 'FR7 Accept Offer',
          listingPrice: 80,
          offerPrice: 60,
        );

        final sellerNotification = (await _notificationsForListing(
          serviceClient,
          listingId,
        )).single;

        await _signInSeller(client, serviceClient);
        final provider = NotificationProvider();
        await provider.acceptOffer(AppNotification.fromMap(sellerNotification));

        final product = await serviceClient
            .from('products')
            .select('is_sold, buyer_id, order_status, price')
            .eq('id', listingId)
            .single();
        expect(product['is_sold'], isTrue);
        expect(product['buyer_id'], buyer1Id);
        expect(product['order_status'], 'pending');
        expect((product['price'] as num).toDouble(), 60);

        final offers = await _offersForListing(serviceClient, listingId);
        expect(offers.single['status'], 'accepted');

        final notifications = await _notificationsForListing(
          serviceClient,
          listingId,
        );
        expect(
          notifications.where((row) => row['notif_type'] == 'offer_received'),
          isEmpty,
        );
        expect(
          notifications.where(
            (row) =>
                row['user_id'] == buyer1Id &&
                row['notif_type'] == 'offer_accepted',
          ),
          hasLength(1),
        );
      },
    );

    test('seller rejects offer: offer declined and buyer notified', () async {
      final listingId = await seedListing(name: 'FR7 Decline Offer', price: 90);
      await _signInBuyer(client, serviceClient, 2);
      await _submitOfferLikeProductDetail(
        buyerId: buyer2Id,
        sellerId: sellerId,
        listingId: listingId,
        listingTitle: 'FR7 Decline Offer',
        listingPrice: 90,
        offerPrice: 40,
      );

      final sellerNotification = (await _notificationsForListing(
        serviceClient,
        listingId,
      )).single;

      await _signInSeller(client, serviceClient);
      final provider = NotificationProvider();
      await provider.declineOffer(AppNotification.fromMap(sellerNotification));

      final offers = await _offersForListing(serviceClient, listingId);
      expect(offers.single['status'], 'declined');

      final product = await serviceClient
          .from('products')
          .select('is_sold, buyer_id')
          .eq('id', listingId)
          .single();
      expect(product['is_sold'], isFalse);
      expect(product['buyer_id'], isNull);

      final notifications = await _notificationsForListing(
        serviceClient,
        listingId,
      );
      expect(
        notifications.where((row) => row['notif_type'] == 'offer_received'),
        isEmpty,
      );
      expect(
        notifications.where(
          (row) =>
              row['user_id'] == buyer2Id &&
              row['notif_type'] == 'offer_declined',
        ),
        hasLength(1),
      );
    });

    test('invalid offer values are blocked before database insert', () async {
      final listingId = await seedListing(name: 'FR7 Invalid Offer Values');
      await _signInBuyer(client, serviceClient, 1);

      expect(
        await _submitOfferLikeProductDetail(
          buyerId: buyer1Id,
          sellerId: sellerId,
          listingId: listingId,
          listingTitle: 'FR7 Invalid Offer Values',
          listingPrice: 100,
          offerPrice: null,
        ),
        'Offer amount required',
      );
      expect(
        await _submitOfferLikeProductDetail(
          buyerId: buyer1Id,
          sellerId: sellerId,
          listingId: listingId,
          listingTitle: 'FR7 Invalid Offer Values',
          listingPrice: 100,
          offerPrice: 120,
        ),
        'Offer cannot exceed listing price',
      );

      expect(await _offersForListing(serviceClient, listingId), isEmpty);
      expect(await _notificationsForListing(serviceClient, listingId), isEmpty);
    });

    test('buyer cannot offer on own listing', () async {
      final listingId = await seedListing(name: 'FR7 Own Listing');

      final error = await _submitOfferLikeProductDetail(
        buyerId: sellerId,
        sellerId: sellerId,
        listingId: listingId,
        listingTitle: 'FR7 Own Listing',
        listingPrice: 100,
        offerPrice: 35,
      );

      expect(error, 'Buyer cannot offer on own listing');
      expect(await _offersForListing(serviceClient, listingId), isEmpty);
      expect(await _notificationsForListing(serviceClient, listingId), isEmpty);
    });

    test(
      'seller response to non-existent offer does not corrupt data',
      () async {
        final listingId = await seedListing(name: 'FR7 Nonexistent Offer');
        await _signInSeller(client, serviceClient);
        await OfferProvider.updateOfferStatus(
          listingId: listingId,
          buyerId: buyer1Id,
          status: 'accepted',
        );

        final product = await serviceClient
            .from('products')
            .select('is_sold, buyer_id')
            .eq('id', listingId)
            .single();
        expect(product['is_sold'], isFalse);
        expect(product['buyer_id'], isNull);
        expect(await _offersForListing(serviceClient, listingId), isEmpty);
        expect(
          await _notificationsForListing(serviceClient, listingId),
          isEmpty,
        );
      },
    );
  });
}
