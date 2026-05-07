import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/providers/cart_provider.dart';
import 'package:thryft/screens/user_profile_screen.dart';
import '../helpers/mock_supabase.dart';

// Instead of talking to the real internet or waiting for a real database,
// these 'Fake' classes just pretend to run the database queries so the app doesn't crash.
// They safely intercept the chain of commands and immediately hand over the ready-made data we give them.

// This intercepts the `.eq()` command for single items (like a user profile)
// and gets ready to hand over our completely hard-coded Map.
class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? data;
  FakeFilterBuilder(this.data);
  @override
  FakeFilterBuilder eq(String column, Object value) => this;
  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeTransformBuilder(data);
}

// This is the end of the line for single-item queries.
// It actually hands the mock data back to the app as if it just downloaded it.
class FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? data;
  FakeTransformBuilder(this.data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) =>
      Future<Map<String, dynamic>?>.value(data).then(onValue, onError: onError);
}

// This pretends to handle commands like `.eq()`, `.filter()`, and `.order()`
// for lists (like a list of products or ratings) just to keep the program running happily.
class FakeListFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeListFilterBuilder(this.data);
  @override
  FakeListFilterBuilder eq(String column, Object value) => this;
  @override
  FakeListFilterBuilder filter(String column, String operator, Object? value) =>
      this;
  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => FakeListTransformBuilder(data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) => Future<List<Map<String, dynamic>>>.value(
    data,
  ).then(onValue, onError: onError);
}

// This is the end of the line for list queries.
// It hands our hard-coded lists of data back to the app as if they just downloaded.
class FakeListTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  FakeListTransformBuilder(this.data);
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) => Future<List<Map<String, dynamic>>>.value(
    data,
  ).then(onValue, onError: onError);
}

void main() {
  setUpAll(() async {
    // Avoid Shared Preferences breaking tests that use context features internally
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://mock.supabase.co', anonKey: 'mock');
  });

  // A helper function that injects mock datasets into our specific Supabase Tables and mounts the screen.
  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    required MockSupabaseClient mockClient,
    Map<String, dynamic>? profileData,
    List<Map<String, dynamic>> productsData = const [],
    List<Map<String, dynamic>> ratingsData = const [],
    List<Map<String, dynamic>> soldData = const [],
  }) async {
    final mockAuth = MockGoTrueClient();
    final mockUser = MockUser();

    // Mock the active authorized user session
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('testuser');

    // 1. Mock 'profiles' table fetch
    final profileQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
    when(
      () => profileQB.select('*, created_at'),
    ).thenAnswer((_) => FakeFilterBuilder(profileData));

    // 2. Mock 'products' table fetch (active listings vs sold items)
    final productsQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('products')).thenAnswer((_) => productsQB);
    when(
      () => productsQB.select(),
    ).thenAnswer((_) => FakeListFilterBuilder(productsData));
    when(
      () => productsQB.select('id'),
    ).thenAnswer((_) => FakeListFilterBuilder(soldData));

    // 3. Mock 'ratings' table fetch (with foreign key mappings correctly expanded)
    final ratingsQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('ratings')).thenAnswer((_) => ratingsQB);
    when(
      () => ratingsQB.select(
        '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
      ),
    ).thenAnswer((_) => FakeListFilterBuilder(ratingsData));

    // 4. Pump the actual widget, wrapping it with necessary architecture (Providers)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: MaterialApp(
          home: UserProfileScreen(
            userId: 'test_seller_id',
            supabaseClient: mockClient,
          ),
        ),
      ),
    );
    await tester
        .pumpAndSettle(); // Allows parsing / animations to finish loading
  }

  // TEST CASES

  testWidgets(
    'Partitions 1, 2 & 5: View existing account with ratings, reviews, and sold items',
    (tester) async {
      final mockClient = MockSupabaseClient();
      await pumpProfileScreen(
        tester,
        mockClient: mockClient,
        profileData: {
          'username': 'TrustySeller',
          'created_at': '2022-01-01T00:00:00.000Z',
        },
        ratingsData: [
          {
            'id': 1,
            'rating': 5,
            'comment': 'Perfect condition!',
            'created_at': '2023-01-01T00:00:00.000Z',
            'products': {'brand': 'Nike', 'price': 100},
            'profiles': {'username': 'BuyerBob'},
          },
        ],
        soldData: [
          {'id': 'prod1'},
          {'id': 'prod2'},
          {'id': 'prod3'},
        ],
      );

      expect(find.text('TrustySeller'), findsNWidgets(2));
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('Rating (1)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
    },
  );

  testWidgets(
    'Partitions 3 & 4: View existing account with 0 ratings and 0 reviews',
    (tester) async {
      final mockClient = MockSupabaseClient();
      await pumpProfileScreen(
        tester,
        mockClient: mockClient,
        profileData: {
          'username': 'NewSeller',
          'created_at': '2022-01-01T00:00:00.000Z',
        },
        ratingsData: [],
        soldData: [],
      );

      expect(find.text('NewSeller'), findsNWidgets(2));
      expect(find.text('N/A'), findsOneWidget);
      expect(find.text('No reviews'), findsOneWidget);
    },
  );

  testWidgets('Partition 6: View seller trust info of invalid userID', (
    tester,
  ) async {
    final mockClient = MockSupabaseClient();
    await pumpProfileScreen(tester, mockClient: mockClient, profileData: null);

    expect(find.text('User not found.'), findsOneWidget);
    expect(find.text('Sold'), findsNothing);
  });

  testWidgets('Partition 7: View seller trust info while logged out', (
    tester,
  ) async {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null); // Logged out

    final profileQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
    when(() => profileQB.select('*, created_at')).thenAnswer(
      (_) => FakeFilterBuilder({
        'username': 'PublicSeller',
        'created_at': '2022-01-01T00:00:00.000Z',
      }),
    );

    final productsQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('products')).thenAnswer((_) => productsQB);
    when(
      () => productsQB.select(),
    ).thenAnswer((_) => FakeListFilterBuilder([]));
    when(() => productsQB.select('id')).thenAnswer(
      (_) => FakeListFilterBuilder([
        {'id': 'prod1'},
      ]),
    );

    final ratingsQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('ratings')).thenAnswer((_) => ratingsQB);
    when(
      () => ratingsQB.select(
        '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
      ),
    ).thenAnswer((_) => FakeListFilterBuilder([]));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: MaterialApp(
          home: UserProfileScreen(
            userId: 'test_seller_id',
            supabaseClient: mockClient,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PublicSeller'), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Sold'), findsOneWidget);
  });
}
