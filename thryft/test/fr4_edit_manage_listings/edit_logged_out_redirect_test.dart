// Tests for FR4 #9 — auth guard on edit/manage listing routes.
// Verifies that requireAuth() in router.dart sends logged-out users to
// /auth and lets logged-in users through, using a real Supabase session
// against the test project instead of a mock client.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';
import '../helpers/supabase_test_client.dart';

// Reuses the existing fr4 seller account that other FR4 tests already
// create — avoids signing up new users on every CI run.
const _email = 'fr4.seller@thryft-test.local';
const _password = 'Thryft!test99';

void main() {
  if (!hasTestCredentials) {
    test(
      'FR4 #9 redirect guard',
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

  group('FR4 #9 — logged-out redirect guard', () {
    test('returns /auth when no user is logged in', () async {
      await client.auth.signOut();

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      try {
        await client.auth.signInWithPassword(
          email: _email,
          password: _password,
        );
      } on AuthException {
        await client.auth.signUp(email: _email, password: _password);
      }

      expect(requireAuth(client), isNull);
    });
  });
}
