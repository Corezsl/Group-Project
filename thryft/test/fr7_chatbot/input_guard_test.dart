import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/models/chat_message.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockChatService extends Mock implements ChatService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

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
// FR7 — Input guards (empty input & rate limiting)
// ---------------------------------------------------------------------------

void main() {
  late MockChatService chatService;
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;

  setUp(() {
    chatService = MockChatService();
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);
  });

  group('FR7 — empty / whitespace-only input guard', () {
    test('pure spaces message is rejected — no state change', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      final beforeCount = provider.messages.length;
      await provider.send('    ');
      final afterCount = provider.messages.length;

      expect(afterCount, equals(beforeCount));
      verifyNever(() => chatService.getAssistantResponse(any()));
    });

    test('empty string message is rejected — no state change', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      final beforeCount = provider.messages.length;
      await provider.send('');
      final afterCount = provider.messages.length;

      expect(afterCount, equals(beforeCount));
      verifyNever(() => chatService.getAssistantResponse(any()));
    });

    test('tabs and newlines are treated as empty — rejected', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      final beforeCount = provider.messages.length;
      await provider.send('\t\n  \t');
      final afterCount = provider.messages.length;

      expect(afterCount, equals(beforeCount));
    });

    test('valid message after empty still works normally', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      // First send empty — ignored.
      await provider.send('   ');

      // Then send valid — processed.
      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      await provider.send('tell me about returns');

      // One welcome + one user + one assistant = 3 messages.
      expect(provider.messages.length, equals(3));
      final userMsg = provider.messages[1];
      expect(userMsg.role, equals(ChatRole.user));
      expect(userMsg.content, equals('tell me about returns'));
    });
  });

  group('FR7 — rate-limit / rapid-send guard', () {
    test('rapid consecutive sends are ignored (600 ms cooldown)', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      // Stub the backend so the first send completes normally.
      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      // First valid send.
      await provider.send('first message');
      final countAfterFirst = provider.messages.length;

      // Immediately send again — should be blocked by cooldown.
      await provider.send('second message');
      final countAfterSecond = provider.messages.length;

      // No additional messages from the second send.
      expect(countAfterSecond, equals(countAfterFirst));
      verify(() => chatService.getAssistantResponse(any())).called(1);
    });

    test('slow consecutive sends are both processed', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      // First send.
      await provider.send('first message');

      // Wait longer than the 600 ms cooldown.
      await Future<void>.delayed(const Duration(milliseconds: 650));

      // Second send should now be allowed.
      await provider.send('second message');

      // Welcome + 2×(user + assistant) = 5 messages.
      expect(provider.messages.length, equals(5));
      verify(() => chatService.getAssistantResponse(any())).called(2);
    });

    test('isSending flag blocks overlapping send attempts', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      // Delay the first backend response so _isSending stays true.
      when(() => chatService.getAssistantResponse(any())).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'Delayed response.';
        },
      );

      // Start first send but don't await it fully yet.
      final firstSend = provider.send('first message');

      // While first is still in-flight, try a second.
      await provider.send('second message');

      // Wait for the first to finish.
      await firstSend;

      // Only one user message and one assistant message should exist
      // beyond the welcome message.
      expect(provider.messages.where((m) => m.role == ChatRole.user).length, equals(1));
      expect(provider.messages.where((m) => m.role == ChatRole.assistant).length, equals(2)); // welcome + one reply
    });
  });
}
