import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';
import 'package:thryft/providers/navigation_assistant.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockChatService extends Mock implements ChatService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockGoRouter extends Mock implements GoRouter {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AssistantChatProvider _createProvider({
  ChatService? chatService,
  SupabaseClient? supabase,
}) {
  return AssistantChatProvider(
    chatService: chatService ?? MockChatService(),
    supabase: supabase ?? MockSupabaseClient(),
  );
}

// ---------------------------------------------------------------------------
// FR7 — Navigation intent matching
// ---------------------------------------------------------------------------

void main() {
  group('FR7 — explicit navigation', () {
    test('"take me to my cart" navigates to /cart', () {
      final match = NavAssistantService().matchTarget('take me to my cart');

      expect(match, isNotNull);
      expect(match!.route, equals('/cart'));
      expect(match.confidence, greaterThan(0.5));
    });

    test('"open my wishlist" navigates to /wishlist', () {
      final match = NavAssistantService().matchTarget('open my wishlist');

      expect(match, isNotNull);
      expect(match!.route, equals('/wishlist'));
    });

    test('"show me my orders" navigates to /my-orders', () {
      final match = NavAssistantService().matchTarget('show me my orders');

      expect(match, isNotNull);
      expect(match!.route, equals('/my-orders'));
    });
  });

  group('FR7 — search-with-query intent', () {
    test('"search for vintage denim jacket" extracts query and builds route', () {
      final match = NavAssistantService().matchTarget('search for vintage denim jacket');

      expect(match, isNotNull);
      expect(match!.route, equals('/search?q=vintage%20denim%20jacket'));
      expect(match.confidence, equals(0.9));
    });

    test('"find nike shoes" extracts query via alternative verb', () {
      final match = NavAssistantService().matchTarget('find nike shoes');

      expect(match, isNotNull);
      expect(match!.route, equals('/search?q=nike%20shoes'));
    });

    test('empty extracted query is rejected', () {
      final match = NavAssistantService().matchTarget('search for   ');

      expect(match, isNull);
    });
  });

  group('FR7 — category browsing', () {
    test('"show me the tops category" navigates to /category/tops', () {
      final match = NavAssistantService().matchTarget('show me the tops category');

      expect(match, isNotNull);
      expect(match!.route, equals('/category/tops'));
      expect(match.confidence, equals(0.9));
    });

    test('"browse footwear" navigates to /category/footwear', () {
      final match = NavAssistantService().matchTarget('browse footwear');

      expect(match, isNotNull);
      expect(match!.route, equals('/category/footwear'));
    });

    test('unknown category is rejected — falls through to AI', () {
      final match = NavAssistantService().matchTarget('browse the electronics category');

      expect(match, isNull);
    });
  });

  group('FR7 — auth guard on protected routes', () {
    test('logged-out user is blocked from /my-orders with friendly message', () async {
      final chatService = MockChatService();
      final auth = MockGoTrueClient();
      final supabase = MockSupabaseClient();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );
      final router = MockGoRouter();

      await provider.send('go to my orders', router: router);

      // No navigation should occur.
      verifyNever(() => router.push(any()));

      // The last message should be the auth-guard reply.
      final messages = provider.messages;
      final last = messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(
        last.content,
        contains("need to be logged in"),
      );
    });

    test('logged-in user is allowed through to protected route', () async {
      final chatService = MockChatService();
      final auth = MockGoTrueClient();
      final supabase = MockSupabaseClient();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(MockUser());

      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );
      final router = MockGoRouter();

      await provider.send('go to my orders', router: router);

      // Navigation should have been scheduled.
      verify(() => router.push('/my-orders')).called(1);

      // Confirmation message should be present.
      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains("Opening"));
    });
  });

  group('FR7 — low-confidence false-positive prevention', () {
    test('casual chat without nav verb is rejected', () {
      final match = NavAssistantService().matchTarget('i really love shopping here');

      expect(match, isNull);
    });

    test('ambiguous input with weak keyword overlap is rejected', () {
      final match = NavAssistantService().matchTarget('dark mode is nice');

      expect(match, isNull);
    });

    test('strong keyword overlap without nav verb still matches', () {
      // "saved items" has heavy wishlist overlap and should pass the
      // no-verb threshold (confidence >= 0.75).
      final match = NavAssistantService().matchTarget('my saved items');

      expect(match, isNotNull);
      expect(match!.route, equals('/wishlist'));
    });
  });

  group('FR7 — confirmation messages', () {
    final nav = NavAssistantService();

    test('search confirmation includes decoded query', () {
      final msg = nav.getConfirmationMessage('/search?q=nike%20shoes');
      expect(msg, equals('Searching for "nike shoes" now!'));
    });

    test('category confirmation names the collection', () {
      final msg = nav.getConfirmationMessage('/category/tops');
      expect(msg, equals('Browsing the tops collection for you!'));
    });

    test('plain route confirmation is friendly', () {
      final msg = nav.getConfirmationMessage('/cart');
      expect(msg, equals('Sure thing! Opening your cart now.'));
    });

    test('home route confirmation is specific', () {
      final msg = nav.getConfirmationMessage('/');
      expect(msg, equals('Heading back to the home page.'));
    });
  });
}
