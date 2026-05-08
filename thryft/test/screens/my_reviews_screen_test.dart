import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:thryft/providers/notification_provider.dart';
import 'package:thryft/providers/search_provider.dart';
import 'package:thryft/screens/my_reviews_screen.dart';
import '../helpers/mock_supabase.dart';

class FakeProfilesFilter extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  FakeProfilesFilter eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() =>
      FakeProfilesTransform();
}

class FakeProfilesTransform extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) => Future<Map<String, dynamic>?>.value({
    'username': 'TestSeller',
  }).then(onValue, onError: onError);
}

class FakeRatingsFilter extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  FakeRatingsFilter eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => FakeRatingsTransform();
}

class FakeRatingsTransform extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    final testData = <Map<String, dynamic>>[
      {
        'id': 1,
        'rating': 5,
        'comment': 'Awesome stuff!',
        'created_at': '2023-10-01T00:00:00.000Z',
        'products': {
          'name': 'Nintendo Switch',
          'brand': 'Nintendo',
          'price': 250.0,
        },
        'profiles': {'username': 'BuyerJohn'},
      },
    ];
    return Future<List<Map<String, dynamic>>>.value(
      testData,
    ).then(onValue, onError: onError);
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://mock.supabase.co', anonKey: 'mock');
  });

  testWidgets('renders my_reviews_screen with mock data', (tester) async {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    final mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('testuser');

    final profileQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
    when(
      () => profileQB.select('username'),
    ).thenAnswer((_) => FakeProfilesFilter());

    final ratingsQB = MockSupabaseQueryBuilder();
    when(() => mockClient.from('ratings')).thenAnswer((_) => ratingsQB);
    when(
      () => ratingsQB.select(
        '*, products(*), profiles!ratings_buyer_profile_fkey(username)',
      ),
    ).thenAnswer((_) => FakeRatingsFilter());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
        ],
        child: MaterialApp(home: MyReviewsScreen(supabaseClient: mockClient)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My Reviews'), findsOneWidget);
    expect(find.text('Awesome stuff!'), findsOneWidget);
    expect(find.text('BuyerJohn'), findsOneWidget);
    expect(find.text('Nintendo Switch'), findsOneWidget);
  });
}
