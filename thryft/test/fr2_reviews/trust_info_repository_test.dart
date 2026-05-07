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
    buyerId = await _signInOrSignUp(
        client, _buyerEmail, _buyerPassword, 'fr4_buyer');

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
}
