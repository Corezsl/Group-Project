import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';
import '../helpers/supabase_test_client.dart';

// ---------------------------------------------------------------------------
// FR5 Partition 6 — View order history while logged out
// Tests the requireAuth guard that protects /my-orders and /sold-items.
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    if (hasTestCredentials) {
      await getTestClient();
    }
  });

  group('FR5 #6 — logged-out redirect guard', () {
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
