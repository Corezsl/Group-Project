// Tests for FR6 (track orders) — auth guard on order-tracking routes.
// Checks that requireAuth() in router.dart sends logged-out users to /auth
// instead of letting them reach /my-orders or /sold-items.
// Used by the router to protect both the buyer and seller order screens.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';

// Fake Supabase classes so we don't need a real auth session in tests.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// Returned by auth.currentUser to simulate a logged-in user.
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    // Link auth to the client so requireAuth() can check currentUser.
    when(() => client.auth).thenReturn(auth);
  });

  // FR6 #7 — logged-out users can't reach /my-orders (buyer order list).
  group('FR6 #7 — logged-out redirect guard for /my-orders (buyer)', () {
    test('returns /auth when no user is logged in', () {
      when(() => auth.currentUser).thenReturn(null); // no session

      // requireAuth returns a redirect path when there's no logged-in user.
      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () {
      when(() => auth.currentUser).thenReturn(MockUser()); // active session

      // null means "let them through" — no redirect needed.
      expect(requireAuth(client), isNull);
    });
  });

  // FR6 #8 — logged-out users can't reach /sold-items (seller ship tracking).
  // Uses the same requireAuth() guard as the buyer route above.
  group('FR6 #8 — logged-out redirect guard for /sold-items (seller)', () {
    test('returns /auth when no user is logged in', () {
      when(() => auth.currentUser).thenReturn(null);

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () {
      when(() => auth.currentUser).thenReturn(MockUser());

      expect(requireAuth(client), isNull);
    });
  });
}
