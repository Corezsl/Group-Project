// Tests for FR7 (chatbot) — navigation intent detection and routing.
// Verifies that navigation commands extract routes and parameters correctly,
// that auth guards block logged-out users from protected routes, and that
// confirmation messages are generated appropriately.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';
import 'package:thryft/providers/navigation_assistant.dart';

// Fake service classes so we don't need real backend or auth in tests.
class MockChatService extends Mock implements ChatService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  final nav = NavAssistantService();

  // FR7 #7 — explicit navigation commands match known routes.
  group('FR7 #7 — explicit navigation routes', () {
    test('"take me to my cart" matches /cart route', () {
      final match = nav.matchTarget('take me to my cart');
      expect(match?.route, equals('/cart'));
      expect(match!.confidence, greaterThan(0.5));
    });

    test('"open my wishlist" matches /wishlist route', () {
      final match = nav.matchTarget('open my wishlist');
      expect(match?.route, equals('/wishlist'));
    });

    test('"show me my orders" matches /my-orders route', () {
      final match = nav.matchTarget('show me my orders');
      expect(match?.route, equals('/my-orders'));
    });
  });

  // FR7 #8 — search queries are extracted and encoded in route.
  group('FR7 #8 — search-with-query intent', () {
    test('extracts query and builds /search?q=... route', () {
      final match = nav.matchTarget('search for vintage denim jacket');
      expect(match?.route, equals('/search?q=vintage%20denim%20jacket'));
      expect(match!.confidence, equals(0.9));
    });

    test('alternative verb "find" also extracts query', () {
      final match = nav.matchTarget('find nike shoes');
      expect(match?.route, equals('/search?q=nike%20shoes'));
    });

    test('empty query rejected — falls through to AI', () {
      expect(nav.matchTarget('search for   '), isNull);
    });
  });

  // FR7 #9 — category browsing matches known category slugs.
  group('FR7 #9 — category browsing', () {
    test('"show me the tops category" matches /category/tops', () {
      final match = nav.matchTarget('show me the tops category');
      expect(match?.route, equals('/category/tops'));
      expect(match!.confidence, equals(0.9));
    });

    test('"browse footwear" matches /category/footwear', () {
      final match = nav.matchTarget('browse footwear');
      expect(match?.route, equals('/category/footwear'));
    });

    test('unknown category rejected — falls through to AI', () {
      expect(nav.matchTarget('browse the electronics category'), isNull);
    });
  });

  // FR7 #10 — auth guard blocks logged-out users from protected routes.
  group('FR7 #10 — auth guard on protected routes (/my-orders)', () {
    test('logged-out user blocked — shows login prompt, no navigation', () async {
      final chatService = MockChatService();
      final auth = MockGoTrueClient();
      final supabase = MockSupabaseClient();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );
      final router = MockGoRouter();

      await provider.send('go to my orders', router: router);

      verifyNever(() => router.push(any()));
      expect(provider.messages.last.content, contains('need to be logged in'));
    });

    test('logged-in user allowed — navigates to protected route', () async {
      final chatService = MockChatService();
      final auth = MockGoTrueClient();
      final supabase = MockSupabaseClient();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(MockUser());

      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );
      final router = MockGoRouter();

      await provider.send('go to my orders', router: router);

      verify(() => router.push('/my-orders')).called(1);
      expect(provider.messages.last.content, contains('Opening'));
    });
  });

  // FR7 #11 — low-confidence inputs rejected to prevent false positives.
  group('FR7 #11 — confidence threshold / false-positive prevention', () {
    test('casual chat without nav verb rejected', () {
      expect(nav.matchTarget('i really love shopping here'), isNull);
    });

    test('ambiguous input with weak keyword overlap rejected', () {
      expect(nav.matchTarget('dark mode is nice'), isNull);
    });

    test('strong keyword overlap without nav verb still matches (>=0.75)', () {
      // "saved items" has heavy wishlist overlap, passes no-verb threshold.
      final match = nav.matchTarget('my saved items');
      expect(match?.route, equals('/wishlist'));
    });
  });

  // FR7 #12 — confirmation messages decoded and formatted per route type.
  group('FR7 #12 — confirmation message generation', () {
    test('search route includes decoded query', () {
      final msg = nav.getConfirmationMessage('/search?q=nike%20shoes');
      expect(msg, equals('Searching for "nike shoes" now!'));
    });

    test('category route names the collection', () {
      expect(nav.getConfirmationMessage('/category/tops'),
          equals('Browsing the tops collection for you!'));
    });

    test('plain route uses friendly confirmation', () {
      expect(nav.getConfirmationMessage('/cart'),
          equals('Sure thing! Opening your cart now.'));
    });

    test('home route uses specific confirmation', () {
      expect(nav.getConfirmationMessage('/'),
          equals('Heading back to the home page.'));
    });
  });
}
