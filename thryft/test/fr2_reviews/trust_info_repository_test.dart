import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/trust_info_repository.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

// ---------------------------------------------------------------------------
// Reuse existing test accounts to avoid hitting email rate limits.
// ---------------------------------------------------------------------------
const _sellerEmail = 'fr4.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

const _buyerEmail = 'fr4.buyer@thryft-test.local';
const _buyerPassword = 'Thryft!test99';

Future<String> _signInOrSignUp(
  SupabaseClient client,
  String email,
  String password,
  String username,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  } on AuthException {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return res.user!.id;
  }
}

void main() {
  if (!hasTestCredentials) {
    test('FR2 integration tests', () {},
        skip: 'No Supabase credentials — pass '
            '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late SupabaseClient admin; // service-role client — bypasses RLS
  late TrustInfoRepository repo;
  late String sellerId;
  late String buyerId;

  setUpAll(() async {
    client = await getTestClient();
    admin = getServiceClient();

    sellerId = await _signInOrSignUp(
        client, _sellerEmail, _sellerPassword, 'fr4_seller');
    await admin.from('profiles').update({'username': 'fr4_seller'}).eq('id', sellerId);
    
    buyerId = await _signInOrSignUp(
        client, _buyerEmail, _buyerPassword, 'fr4_buyer');
    await admin.from('profiles').update({'username': 'fr4_buyer'}).eq('id', buyerId);

    // Run tests as buyer (they are viewing the seller's profile)
    await _signInOrSignUp(client, _buyerEmail, _buyerPassword, 'fr4_buyer');

    repo = TrustInfoRepository(client);
  });

  tearDownAll(() async {
    // Use admin client to bypass RLS (ratings has no DELETE policy).
    await admin.from('ratings').delete().eq('seller_id', sellerId);
    await admin.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  // -------------------------------------------------------------------------
  // FR2 Partitions 1, 2 & 5 — Profile with ratings and sold items
  // -------------------------------------------------------------------------
  group('FR2 #1,2,5 — profile with ratings and sold items', () {
    late String p1, p2, p3, r1;

    setUp(() async {
      // Seed 3 sold products and 1 rating
      await _signInOrSignUp(
          client, _sellerEmail, _sellerPassword, 'fr4_seller');

      p1 = await seedProduct(client,
          sellerId: sellerId,
          buyerId: buyerId,
          isSold: true,
          orderStatus: 'delivered');
      p2 = await seedProduct(client,
          sellerId: sellerId,
          buyerId: buyerId,
          isSold: true,
          orderStatus: 'delivered',
          name: 'FR2 Sold Shirt');
      p3 = await seedProduct(client,
          sellerId: sellerId,
          buyerId: buyerId,
          isSold: true,
          orderStatus: 'delivered',
          name: 'FR2 Sold Jacket');

      await _signInOrSignUp(
          client, _buyerEmail, _buyerPassword, 'fr4_buyer');
      r1 = await seedRating(client,
          sellerId: sellerId,
          buyerId: buyerId,
          productId: p1,
          rating: 5,
          comment: 'Perfect condition!');
    });

    tearDown(() async {
      // Use admin client for cleanup (ratings has no DELETE RLS policy)
      await admin.from('ratings').delete().eq('id', r1);
      await admin.from('products').delete().inFilter('id', [p1, p2, p3]);
    });

    test('fetchProfile returns seller username', () async {
      final profile = await repo.fetchProfile(sellerId);
      expect(profile, isNotNull);
      expect(profile!['username'], 'fr4_seller');
    });

    test('fetchSoldCount returns 3', () async {
      final count = await repo.fetchSoldCount(sellerId);
      expect(count, 3);
    });

    test('fetchRatings returns 1 rating with score 5', () async {
      final ratings = await repo.fetchRatings(sellerId);
      expect(ratings.length, 1);
      expect(ratings.first['rating'], 5);
      expect(ratings.first['comment'], 'Perfect condition!');
    });
  });

  // -------------------------------------------------------------------------
  // FR2 Partitions 3 & 4 — Profile with 0 ratings and 0 reviews
  // -------------------------------------------------------------------------
  group('FR2 #3,4 — profile with 0 ratings', () {
    test('fetchRatings returns empty list for seller with no reviews', () async {
      // Use a UUID that won't match any seller
      const ghostSeller = '00000000-ffff-4000-8000-000000000000';
      final ratings = await repo.fetchRatings(ghostSeller);
      expect(ratings, isEmpty);
    });

    test('fetchSoldCount returns 0 for seller with no sold items', () async {
      const ghostSeller = '00000000-ffff-4000-8000-000000000000';
      final count = await repo.fetchSoldCount(ghostSeller);
      expect(count, 0);
    });
  });

  // -------------------------------------------------------------------------
  // FR2 Partition 6 — Invalid user ID
  // -------------------------------------------------------------------------
  group('FR2 #6 — invalid user ID', () {
    test('fetchProfile returns null for non-existent user', () async {
      const invalidId = '00000000-ffff-4000-8000-000000000000';
      final profile = await repo.fetchProfile(invalidId);
      expect(profile, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // FR2 Partition 7 — Fetch while logged out
  // -------------------------------------------------------------------------
  group('FR2 #7 — fetch while logged out', () {
    late String p1;

    setUp(() async {
      await _signInOrSignUp(
          client, _sellerEmail, _sellerPassword, 'fr4_seller');
      p1 = await seedProduct(client,
          sellerId: sellerId, isSold: true, orderStatus: 'delivered');
      await client.auth.signOut();
    });

    tearDown(() async {
      await admin.from('products').delete().eq('id', p1);
      // Restore buyer session for subsequent tests
      await _signInOrSignUp(
          client, _buyerEmail, _buyerPassword, 'fr4_buyer');
    });

    test('fetchProfile still returns data when signed out', () async {
      final profile = await repo.fetchProfile(sellerId);
      expect(profile, isNotNull);
      expect(profile!['username'], 'fr4_seller');
    });

    test('fetchSoldCount still works when signed out', () async {
      final count = await repo.fetchSoldCount(sellerId);
      expect(count, greaterThanOrEqualTo(1));
    });
  });

  // -------------------------------------------------------------------------
  // FR2 Partition 8 — Own review (buyer_id matches current user)
  // -------------------------------------------------------------------------
  group('FR2 #8 — own review', () {
    late String p1, r1;

    setUp(() async {
      await _signInOrSignUp(
          client, _sellerEmail, _sellerPassword, 'fr4_seller');
      p1 = await seedProduct(client,
          sellerId: sellerId,
          buyerId: buyerId,
          isSold: true,
          orderStatus: 'delivered');

      await _signInOrSignUp(
          client, _buyerEmail, _buyerPassword, 'fr4_buyer');
      r1 = await seedRating(client,
          sellerId: sellerId,
          buyerId: buyerId,
          productId: p1,
          rating: 5,
          comment: 'I bought this and loved it!');
    });

    tearDown(() async {
      await admin.from('ratings').delete().eq('id', r1);
      await admin.from('products').delete().eq('id', p1);
    });

    test('rating buyer_id matches the current user', () async {
      final ratings = await repo.fetchRatings(sellerId);
      final ownReview = ratings.firstWhere((r) => r['id'] == r1);
      expect(ownReview['buyer_id'], buyerId);
    });
  });

  // -------------------------------------------------------------------------
  // FR2 Partition 9 — Other's review (buyer_id != current user)
  // -------------------------------------------------------------------------
  group("FR2 #9 — other user's review", () {
    late String p1, r1, otherUserId;

    setUp(() async {
      // Use the fr5 buyer as a 3rd user
      otherUserId = await _signInOrSignUp(
          client, 'fr5.buyer@thryft-test.local', 'Thryft!test99', 'fr5_buyer');

      await _signInOrSignUp(
          client, _sellerEmail, _sellerPassword, 'fr4_seller');
      p1 = await seedProduct(client,
          sellerId: sellerId,
          buyerId: otherUserId,
          isSold: true,
          orderStatus: 'delivered');

      // Rate as the other user
      await _signInOrSignUp(
          client, 'fr5.buyer@thryft-test.local', 'Thryft!test99', 'fr5_buyer');
      r1 = await seedRating(client,
          sellerId: sellerId,
          buyerId: otherUserId,
          productId: p1,
          rating: 4,
          comment: 'Someone else bought this.');

      // Switch back to main buyer
      await _signInOrSignUp(
          client, _buyerEmail, _buyerPassword, 'fr4_buyer');
    });

    tearDown(() async {
      await admin.from('ratings').delete().eq('id', r1);
      await admin.from('products').delete().eq('id', p1);
    });

    test('rating buyer_id does NOT match the current user', () async {
      final ratings = await repo.fetchRatings(sellerId);
      final otherReview = ratings.firstWhere((r) => r['id'] == r1);
      // The review was left by otherUserId, not buyerId
      expect(otherReview['buyer_id'], isNot(buyerId));
      expect(otherReview['buyer_id'], otherUserId);
    });
  });
}
