// Tests for FR7 (chatbot) — input validation guards for empty/whitespace
// messages and rate limiting (cooldown + overlap protection).
// Verifies that empty input is rejected and rapid sends are throttled.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';

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

  // FR7 #5 — empty or whitespace-only messages are rejected without backend call.
  group('FR7 #5 — empty / whitespace input rejection', () {
    test('pure spaces rejected — no state change, no backend call', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      final beforeCount = provider.messages.length;
      await provider.send('    ');

      expect(provider.messages.length, equals(beforeCount));
      verifyNever(() => chatService.getAssistantResponse(any()));
    });

    test('empty string rejected — no state change', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      final beforeCount = provider.messages.length;
      await provider.send('');

      expect(provider.messages.length, equals(beforeCount));
      verifyNever(() => chatService.getAssistantResponse(any()));
    });

    test('valid message after empty still processed normally', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      // Empty message ignored.
      await provider.send('   ');

      // Valid message processed with backend.
      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');
      await provider.send('tell me about returns');

      // Welcome + user + assistant = 3 messages.
      expect(provider.messages.length, equals(3));
      expect(provider.messages[1].role, equals(ChatRole.user));
    });
  });

  // FR7 #6 — rate limiting prevents spam (600ms cooldown + overlap protection).
  group('FR7 #6 — rate limit / cooldown guard', () {
    test('rapid consecutive sends blocked by 600ms cooldown', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      // First navigation send processed.
      await provider.send('open my wishlist');
      final countAfterFirst = provider.messages.length;

      // Immediate second send blocked (spam prevention).
      await provider.send('go to my cart');

      expect(provider.messages.length, equals(countAfterFirst));
      verify(() => chatService.getAssistantResponse(any())).called(1);
    });

    test('slow consecutive sends allowed after cooldown expires', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      await provider.send('first message');

      // Wait longer than 600ms cooldown.
      await Future<void>.delayed(const Duration(milliseconds: 650));

      await provider.send('second message');

      // Welcome + 2×(user + assistant) = 5 messages.
      expect(provider.messages.length, equals(5));
      verify(() => chatService.getAssistantResponse(any())).called(2);
    });

    test('isSending flag blocks overlapping in-flight requests', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      // Delay backend so _isSending stays true.
      when(() => chatService.getAssistantResponse(any())).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'Delayed response.';
        },
      );

      final firstSend = provider.send('first message');
      await provider.send('second message'); // Blocked while first in-flight.
      await firstSend;

      // Only one user message (welcome + one reply = 2 assistant).
      expect(provider.messages.where((m) => m.role == ChatRole.user).length, equals(1));
      expect(provider.messages.where((m) => m.role == ChatRole.assistant).length, equals(2));
    });
  });
}
