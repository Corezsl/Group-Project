import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// ---------------------------------------------------------------------------
// FR4 Partition 9 — Operation while logged out
// Tests the requireAuth guard that protects /create-listing and /my-listings.
// ---------------------------------------------------------------------------

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  group('FR4 #9 — logged-out redirect guard', () {
    test('returns /auth when no user is logged in', () {
      when(() => auth.currentUser).thenReturn(null);

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () {
      final user = MockUser();
      when(() => auth.currentUser).thenReturn(user);

      expect(requireAuth(client), isNull);
    });
  });
}

class MockUser extends Mock implements User {}
