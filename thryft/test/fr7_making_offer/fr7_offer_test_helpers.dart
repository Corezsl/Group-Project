import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/notification_model.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/offer_provider.dart';

import '../helpers/seed_helper.dart';
import '../helpers/supabase_test_client.dart';

const fr7TestPassword = 'Thryft!test99';

class Fr7OfferTestContext {
  Fr7OfferTestContext(this.scope);

  final String scope;

  late SupabaseClient client;
  late SupabaseClient serviceClient;
  late String sellerId;
  late String buyer1Id;
  late String buyer2Id;
  late String buyer3Id;

  final listingIds = <String>[];
  final userIds = <String>[];

  String get _emailPrefix => 'fr7.$runId.$scope';

  String get _usernamePrefix {
    return 'fr7_${runId}_$scope'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  }

  Future<void> setUpAll() async {
    client = await getTestClient();
    serviceClient = getServiceClient();

    sellerId = await ensureTestUser(
      email: '$_emailPrefix.seller@thryft-test.local',
      username: '${_usernamePrefix}_seller',
    );
    buyer1Id = await ensureTestUser(
      email: '$_emailPrefix.buyer1@thryft-test.local',
      username: '${_usernamePrefix}_buyer_1',
    );
    buyer2Id = await ensureTestUser(
      email: '$_emailPrefix.buyer2@thryft-test.local',
      username: '${_usernamePrefix}_buyer_2',
    );
    buyer3Id = await ensureTestUser(
      email: '$_emailPrefix.buyer3@thryft-test.local',
      username: '${_usernamePrefix}_buyer_3',
    );

    userIds.addAll([sellerId, buyer1Id, buyer2Id, buyer3Id]);
  }

  Future<void> tearDown() async {
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
  }

  Future<void> tearDownAll() async {
    await client.auth.signOut();

    if (userIds.isEmpty) return;

    await serviceClient.from('profiles').delete().inFilter('id', userIds);
    for (final userId in userIds) {
      try {
        await serviceClient.auth.admin.deleteUser(userId);
      } catch (_) {}
    }
  }

  Future<String> ensureTestUser({
    required String email,
    required String username,
  }) async {
    try {
      final created = await serviceClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: fr7TestPassword,
          emailConfirm: true,
          userMetadata: {'username': username},
        ),
      );
      final user = created.user;
      if (user == null) throw StateError('Could not create test user $email');

      await serviceClient.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return user.id;
    } on AuthException catch (e) {
      if (!e.message.contains('already') && !e.message.contains('registered')) {
        rethrow;
      }

      final existing = await _findUserByEmail(email);
      if (existing == null) {
        throw StateError('Test user exists but could not be found: $email');
      }

      await serviceClient.from('profiles').upsert({
        'id': existing.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return existing.id;
    }
  }

  Future<String> _signIn(String email) async {
    final currentUser = client.auth.currentUser;
    if (currentUser?.email == email) return currentUser!.id;

    AuthResponse res;
    try {
      res = await client.auth.signInWithPassword(
        email: email,
        password: fr7TestPassword,
      );
    } on AuthException {
      await client.auth.signOut(scope: SignOutScope.local);
      res = await client.auth.signInWithPassword(
        email: email,
        password: fr7TestPassword,
      );
    }
    return res.user!.id;
  }

  Future<User?> _findUserByEmail(String email) async {
    for (var page = 1; page <= 5; page++) {
      final users = await serviceClient.auth.admin.listUsers(
        page: page,
        perPage: 1000,
      );
      for (final user in users) {
        if (user.email == email) return user;
      }
      if (users.length < 1000) break;
    }
    return null;
  }

  Future<void> signInSeller() async {
    await _signIn('$_emailPrefix.seller@thryft-test.local');
  }

  Future<void> signInBuyer(int buyerNumber) async {
    await _signIn('$_emailPrefix.buyer$buyerNumber@thryft-test.local');
  }

  Future<String> seedListing({required String name, double price = 100}) async {
    final listingId = await seedProduct(
      serviceClient,
      sellerId: sellerId,
      name: name,
      price: price,
    );
    listingIds.add(listingId);
    return listingId;
  }

  Future<String?> submitOfferThroughBackend({
    required String? offerInput,
    required double listingPrice,
    required String listingId,
    required String listingTitle,
    required String buyerId,
    required String sellerId,
  }) async {
    final offerPrice = _parseOfferInput(offerInput);
    OfferProvider.validateOfferOrThrow(
      offerAmount: offerPrice,
      listingPrice: listingPrice,
      buyerId: buyerId,
      sellerId: sellerId,
    );
    final validOfferPrice = offerPrice!;

    final alreadyPending = await OfferProvider.hasPendingOffer(
      buyerId: buyerId,
      listingId: listingId,
    );
    if (alreadyPending) return 'Pending offer already exists';

    final offerId = await OfferProvider.createOffer(
      buyerId: buyerId,
      sellerId: sellerId,
      listingId: listingId,
      offerAmount: validOfferPrice,
      listingTitle: listingTitle,
    );
    if (offerId == null) return 'Offer could not be saved';

    await NotificationProvider.insertNotification(
      userId: sellerId,
      type: NotificationType.offerReceived,
      content:
          'Buyer offered GBP ${validOfferPrice.toStringAsFixed(2)} for "$listingTitle"',
      listingId: listingId,
      relatedUserId: buyerId,
      offerPrice: validOfferPrice,
    );

    return null;
  }

  Future<List<dynamic>> offersForListing(String listingId) {
    return serviceClient
        .from('offers')
        .select()
        .eq('listing_id', listingId)
        .order('offer_id', ascending: true);
  }

  Future<List<dynamic>> notificationsForListing(String listingId) {
    return serviceClient
        .from('notification')
        .select()
        .eq('listing_id', listingId)
        .order('notification_id', ascending: true);
  }
}

double? _parseOfferInput(String? input) {
  if (input == null) return null;
  return double.tryParse(input.trim());
}
