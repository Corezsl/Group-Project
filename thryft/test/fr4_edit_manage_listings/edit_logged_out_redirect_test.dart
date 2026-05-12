import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';
import '../helpers/supabase_test_client.dart';

// ---------------------------------------------------------------------------
// FR4 Partition 9 — Operation while logged out
// Tests the requireAuth guard that protects /create-listing and /my-listings.
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    if (hasTestCredentials) {
      await getTestClient();
    }
  });

  group('FR4 #9 — logged-out redirect guard', () {
    test('returns /auth when no user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;
      await client.auth.signOut();

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () async {
      if (!hasTestCredentials) return;
      final client = Supabase.instance.client;

      // Note: expects the seeded seller user to exist
      await client.auth.signInWithPassword(
        email: 'fr4.seller@thryft-test.local',
        password: 'Thryft!test99',
      );

      expect(requireAuth(client), isNull);

      await client.auth.signOut();
    });
  });
}
