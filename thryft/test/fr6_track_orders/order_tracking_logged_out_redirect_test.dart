import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/router.dart';

// Mocks

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

// FR6 Partition 7 / 8 — Auth guard for order tracking routes.


void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
  });

  // /my-orders route guard (buyer order tracking)
  group('FR6 #7 — logged-out redirect guard for /my-orders (buyer)', () {
    test('returns /auth when no user is logged in', () {
      when(() => auth.currentUser).thenReturn(null);

      expect(requireAuth(client), equals('/auth'));
    });

    test('returns null (allow) when a user is logged in', () {
      when(() => auth.currentUser).thenReturn(MockUser());

      expect(requireAuth(client), isNull);
    });
  });

  // /sold-items route guard (seller ship tracking)
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
