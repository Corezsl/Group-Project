// Tests for FR6 (track orders) — auth guard on order-tracking routes.
// Checks that requireAuth() in router.dart sends logged-out users to /auth
// instead of letting them reach /my-orders or /sold-items.
// Used by the router to protect both the buyer and seller order screens.
// Runs against the live test Supabase project — no mocking.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';
import '../helpers/supabase_test_client.dart';

// Reuses the existing fr6 seller account that other FR6 tests already
// create — avoids signing up new users on every CI run.
const _email = 'fr6.seller@thryft-test.local';
const _password = 'Thryft!test99';

void main() {
  if (!hasTestCredentials) {
    test(
      'FR6 redirect guard',
      () {},
      skip: 'No Supabase credentials — pass --dart-define=TEST_SUPABASE_URL '
          'and TEST_SUPABASE_ANON_KEY to run',
    );
    return;
  }

  late SupabaseClient client;

  setUpAll(() async {
    client = await getTestClient();
  });

  tearDownAll(() async {
    await client.auth.signOut();
  });

  // Signs the test user in, creating the account on first run if needed.
  Future<void> signIn() async {
    try {
      await client.auth.signInWithPassword(
        email: _email,
        password: _password,
      );
    } on AuthException {
      await client.auth.signUp(email: _email, password: _password);
    }
  }

  // FR6 #7 — logged-out users can't reach /my-orders (buyer order list).
  group('FR6 #7 — logged-out redirect guard for /my-orders (buyer)', () {
    test('returns /auth when no user is logged in', () async {
      await client.auth.signOut();

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      await signIn();

      expect(requireAuth(client), isNull);
    });
  });

  // FR6 #8 — logged-out users can't reach /sold-items (seller ship tracking).
  // Uses the same requireAuth() guard as the buyer route above.
  group('FR6 #8 — logged-out redirect guard for /sold-items (seller)', () {
    test('returns /auth when no user is logged in', () async {
      await client.auth.signOut();

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      await signIn();

      expect(requireAuth(client), isNull);
    });
  });
}
