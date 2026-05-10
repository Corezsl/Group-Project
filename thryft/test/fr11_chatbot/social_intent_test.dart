// Tests for FR7 (chatbot) — social intent detection for greetings, farewells, and thanks.
// Verifies that detectSocialIntent() returns appropriate local responses without
// calling the backend, and returns null for non-social input (navigation/quick-help).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';
import 'package:thryft/providers/navigation_assistant.dart';

// Fake service classes so we don't need real backend calls in tests.
class MockChatService extends Mock implements ChatService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockChatService chatService;
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;

  setUp(() {
    chatService = MockChatService();
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    // Link auth so the provider can check currentUser if needed.
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);
  });

  // FR7 #1 — greeting intents handled locally without backend call.
  group('FR7 #1 — greeting responses (hi, hello, hey)', () {
    test('returns greeting message for "hi" — no backend call', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hi');

      // Social intents should NOT trigger backend response.
      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });

    test('returns greeting message for "hello there!"', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hello there!');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });
  });

  // FR7 #2 — farewell intents handled locally without backend call.
  group('FR7 #2 — farewell responses (bye, goodbye, see you)', () {
    test('returns goodbye message for "bye" — no backend call', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('bye');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Goodbye'));
    });

    test('returns goodbye message for "see you later"', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('see you later');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Goodbye'));
    });
  });

  // FR7 #3 — thanks intents handled locally without backend call.
  group('FR7 #3 — thanks responses (thanks, ty, cheers)', () {
    test('returns welcome message for "thanks" — no backend call', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('thanks');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('welcome'));
    });

    test('returns welcome message for "cheers"', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('cheers');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('welcome'));
    });
  });

  // FR7 #4 — detectSocialIntent returns null for non-social input.
  group('FR7 #4 — non-social input returns null (no local response)', () {
    final nav = NavAssistantService();

    test('navigation input returns null — will use backend', () {
      // "open my cart" is a navigation intent, not social.
      final reply = nav.detectSocialIntent('open my cart');
      expect(reply, isNull);
    });

    test('quick-help input returns null — will use backend', () {
      // "how do i sell" is a help intent, not social.
      final reply = nav.detectSocialIntent('how do i sell');
      expect(reply, isNull);
    });
  });
}
