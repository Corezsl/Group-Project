// Live integration test for MyReviewsScreen — seeds a real product and
// rating into the test Supabase project, signs in the seller, and pumps
// the screen against Supabase.instance.client (no mocking).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/screens/my_reviews_screen.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

// Reuses fr4 test accounts which are already created and in active use
// by other integration tests, so we don't hit the "new user" error path.
const _sellerEmail = 'fr4.seller@thryft-test.local';
const _buyerEmail = 'fr4.buyer@thryft-test.local';
const _password = 'Thryft!test99';

Future<String> _ensureSignedIn(
  SupabaseClient client,
  String email,
  String password,
) async {
  try {
    final res = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user!.id;
  } on AuthException {
    final res = await client.auth.signUp(email: email, password: password);
    return res.user!.id;
  }
}

void main() {
  if (!hasTestCredentials) {
    test(
      'MyReviewsScreen',
      () {},
      skip: 'No Supabase credentials — pass --dart-define=TEST_SUPABASE_URL '
          'and TEST_SUPABASE_ANON_KEY to run',
    );
    return;
  }

  late SupabaseClient client;
  late String sellerId;
  late String buyerId;
  late String productId;
  late String ratingId;

  setUpAll(() async {
    client = await getTestClient();

    // Capture both real auth.users ids by signing each user in once.
    buyerId = await _ensureSignedIn(client, _buyerEmail, _password);
    sellerId = await _ensureSignedIn(client, _sellerEmail, _password);

    // Make sure the seller profile row exists so the screen's username
    // lookup doesn't return null.
    await client.from('profiles').upsert({
      'id': sellerId,
      'username': 'TestSeller',
      'rating': 0.0,
      'rating_count': 0,
    });

    // Insert the sold product under the seller's session (matches RLS).
    productId = await seedProduct(
      client,
      sellerId: sellerId,
      name: 'Nintendo Switch',
      brand: 'Nintendo',
      price: 250.0,
      isSold: true,
      buyerId: buyerId,
    );

    // RLS only lets the buyer insert ratings, so switch sessions to seed it.
    await _ensureSignedIn(client, _buyerEmail, _password);
    ratingId = await seedRating(
      client,
      sellerId: sellerId,
      buyerId: buyerId,
      productId: productId,
      rating: 5,
      comment: 'Awesome stuff!',
    );

    // Switch back — the widget renders under the seller's session.
    await _ensureSignedIn(client, _sellerEmail, _password);
  });

  tearDownAll(() async {
    // Use the service-role client for cleanup to bypass RLS — the seller
    // session can't delete a rating they didn't create.
    final admin = getServiceClient();
    await admin.from('ratings').delete().eq('id', ratingId);
    await admin.from('products').delete().eq('id', productId);
    await client.auth.signOut();
  });

  testWidgets('renders MyReviewsScreen with live data', (tester) async {
    // testWidgets runs in a fake-async zone where real HTTP calls never
    // progress. runAsync escapes that zone so the screen's initState fetch
    // can hit the real DB; we then pump frames to apply the setState that
    // populates _ratings.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            // Use the test-only ctor so we don't open a realtime channel
            // that keeps firing after the widget tree is disposed.
            ChangeNotifierProvider(create: (_) => NotificationProvider.test()),
            ChangeNotifierProvider(create: (_) => SearchProvider()),
          ],
          child: const MaterialApp(home: MyReviewsScreen()),
        ),
      );
      // Allow the profile + ratings queries to complete.
      await Future.delayed(const Duration(seconds: 3));
    });

    // Pump a couple of frames to let the setState in _fetchReviews flush.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Older failed runs may have left additional ratings/products tied to
    // the same seller account, so we use findsAtLeastNWidgets(1) here.
    expect(find.text('My Reviews'), findsOneWidget);
    expect(find.text('Awesome stuff!'), findsAtLeastNWidgets(1));
    expect(find.text('Nintendo Switch'), findsAtLeastNWidgets(1));
  });
}
