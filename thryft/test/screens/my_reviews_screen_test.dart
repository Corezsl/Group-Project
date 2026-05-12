import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/screens/my_reviews_screen.dart';
import '../helpers/supabase_test_client.dart';
import '../helpers/seed_helper.dart';

void main() {
  late SupabaseClient client;
  late SupabaseClient admin;
  late String sellerId;
  late String buyerId;
  late String buyerName;

  setUpAll(() async {
    if (!hasTestCredentials) return;
    client = await getTestClient();
    admin = getServiceClient();

    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final sellerName = 'TestSeller_$ts';
    buyerName = 'BuyerJohn_$ts';

    sellerId = await seedUser(admin, username: sellerName);
    await admin.from('profiles').update({'username': sellerName}).eq('id', sellerId);

    buyerId = await seedUser(admin, username: buyerName);
    await admin.from('profiles').update({'username': buyerName}).eq('id', buyerId);

    // Create a sold product
    final p1 = await seedProduct(admin,
        sellerId: sellerId,
        buyerId: buyerId,
        name: 'Nintendo Switch',
        brand: 'Nintendo',
        price: 250.0,
        isSold: true,
        orderStatus: 'delivered');

    // Rate it
    await seedRating(admin,
        sellerId: sellerId,
        buyerId: buyerId,
        productId: p1,
        rating: 5,
        comment: 'Awesome stuff!');

    // Sign in as the seller so MyReviewsScreen loads their reviews
    // Since seedUser uses a deterministic prefix, we don't know the exact email
    // but the email is in the form '$userIdPrefix@thryft-test.local'.
    // We can get the email directly from auth.users via admin.
    final userRes = await admin.auth.admin.getUserById(sellerId);
    await client.auth.signInWithPassword(
      email: userRes.user!.email,
      password: 'Password123!',
    );
  });

  tearDownAll(() async {
    if (!hasTestCredentials) return;
    await tearDownTestData(admin);
    await client.auth.signOut();
  });

  testWidgets('renders my_reviews_screen with real data', (tester) async {
    if (!hasTestCredentials) return;

    // pumpWidget must happen inside runAsync so that initState → _fetchReviews()
    // fires real HTTP requests within the real event loop (not the fake test zone).
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => SearchProvider()),
          ],
          child: MaterialApp(home: MyReviewsScreen(supabaseClient: client)),
        ),
      );

      // Give the network call time to round-trip to Supabase
      await Future.delayed(const Duration(seconds: 5));
    });

    // Rebuild after setState from _fetchReviews has fired
    await tester.pump();

    expect(find.text('My Reviews'), findsOneWidget);
    expect(find.text('Awesome stuff!'), findsOneWidget);
    expect(find.text(buyerName), findsOneWidget);
    expect(find.text('Nintendo Switch'), findsOneWidget);

    // Tear down the widget tree inside runAsync so the NotificationProvider's
    // realtime subscription is cleanly cancelled before the test zone closes.
    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future.delayed(const Duration(milliseconds: 500));
    });
  });
}
