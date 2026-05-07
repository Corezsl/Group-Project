import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/screens/user_profile_screen.dart';

import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

// ---------------------------------------------------------------------------
// Test credentials — fixed per file so re-runs reuse the same auth user
// instead of creating a new one each time.
// ---------------------------------------------------------------------------
const _sellerEmail = 'fr2.seller@thryft-test.local';
const _sellerPassword = 'Thryft!test99';

const _buyerEmail = 'fr2.buyer@thryft-test.local';
const _buyerPassword = 'Thryft!test99';

/// Sign in if the user already exists, sign up on first run.
Future<String> _ensureSignedIn(SupabaseClient client, String email, String password, String username) async {
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
  // Skip the entire suite when --dart-define credentials haven't been supplied
  if (!hasTestCredentials) {
    test('FR2 integration tests', () {}, skip: 'No Supabase credentials — pass '
        '--dart-define=TEST_SUPABASE_URL and TEST_SUPABASE_ANON_KEY to run');
    return;
  }

  late SupabaseClient client;
  late String sellerId;
  late String buyerId;

  setUpAll(() async {
    client = await getTestClient();

    // Register / sign in the seller first.
    sellerId = await _ensureSignedIn(client, _sellerEmail, _sellerPassword, 'fr2_seller');

    // Register / sign in the buyer.
    buyerId = await _ensureSignedIn(client, _buyerEmail, _buyerPassword, 'fr2_buyer');

    // Switch back to buyer since they are the one viewing the seller's profile
    await _ensureSignedIn(client, _buyerEmail, _buyerPassword, 'fr2_buyer');
  });

  tearDownAll(() async {
    // Clean up seeded data for this run using the helper.
    await tearDownTestData(client);
    
    // Also explicitly clean up products and ratings associated with the test seller.
    await client.from('ratings').delete().eq('seller_id', sellerId);
    await client.from('products').delete().eq('user_id', sellerId);
    await client.auth.signOut();
  });

  // A helper function to mount the UserProfileScreen with necessary providers
  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    required SupabaseClient supabaseClient,
    required String targetUserId,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: MaterialApp(
          home: UserProfileScreen(
            userId: targetUserId,
            supabaseClient: supabaseClient,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FR2 Live Tests', () {
    // Tests will go here
  });
}
