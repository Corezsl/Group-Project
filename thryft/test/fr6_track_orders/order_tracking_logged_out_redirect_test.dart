import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';
import '../helpers/supabase_test_client.dart';

// Tests for FR6 (track orders) — auth guard on order-tracking routes.
// Checks that requireAuth() in router.dart sends logged-out users to /auth
// instead of letting them reach /my-orders or /sold-items.
// Used by the router to protect both the buyer and seller order screens.

void main() {
  setUpAll(() async {
    if (hasTestCredentials) {
      await getTestClient();
    }
  });

  // FR6 #7 — logged-out users can't reach /my-orders (buyer order list).
  group('FR6 #7 — logged-out redirect guard for /my-orders (buyer)', () {
    test('returns /auth when no user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;
      await client.auth.signOut();

      // requireAuth returns a redirect path when there's no logged-in user.
      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;

      await client.auth.signInWithPassword(
        email: 'fr4.seller@thryft-test.local',
        password: 'Thryft!test99',
      );

      // null means "let them through" — no redirect needed.
      expect(requireAuth(client), isNull);

      await client.auth.signOut();
    });
  });

  // FR6 #8 — logged-out users can't reach /sold-items (seller ship tracking).
  // Uses the same requireAuth() guard as the buyer route above.
  group('FR6 #8 — logged-out redirect guard for /sold-items (seller)', () {
    test('returns /auth when no user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;
      await client.auth.signOut();

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;

      await client.auth.signInWithPassword(
        email: 'fr4.seller@thryft-test.local',
        password: 'Thryft!test99',
      );

      expect(requireAuth(client), isNull);

      await client.auth.signOut();
    });
  });
}
