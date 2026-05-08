import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
// FR7 — Social intents (greetings, farewells, thanks)
// Handled locally without any backend call.
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

  group('FR7 — greeting responses', () {
    test('"hi" returns friendly greeting', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hi');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });

    test('"hello there!" returns greeting', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hello there!');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });

    test('"good morning" returns greeting', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('good morning');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });

    test('"hey" returns greeting', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hey');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Hey there'));
    });
  });

  group('FR7 — farewell responses', () {
    test('"bye" returns goodbye message', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('bye');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Goodbye'));
    });

    test('"see you later" returns goodbye message', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('see you later');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Goodbye'));
    });

    test('"goodbye" returns goodbye message', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('goodbye');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Goodbye'));
    });
  });

  group('FR7 — thanks responses', () {
    test('"thanks" returns acknowledgement', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('thanks');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('welcome'));
    });

    test('"thank you so much" returns acknowledgement', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('thank you so much');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('welcome'));
    });

    test('"cheers" returns acknowledgement', () async {
      final provider = _createProvider(
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

  group('FR7 — detectSocialIntent direct unit tests', () {
    final nav = NavAssistantService();

    test('detects greeting intent', () {
      final reply = nav.detectSocialIntent('hi there');
      expect(reply, isNotNull);
      expect(reply, contains('Hey there'));
    });

    test('detects farewell intent', () {
      final reply = nav.detectSocialIntent('goodbye for now');
      expect(reply, isNotNull);
      expect(reply, contains('Goodbye'));
    });

    test('detects thanks intent', () {
      final reply = nav.detectSocialIntent('ty');
      expect(reply, isNotNull);
      expect(reply, contains('welcome'));
    });

    test('returns null for normal navigational input', () {
      final reply = nav.detectSocialIntent('open my cart');
      expect(reply, isNull);
    });

    test('returns null for quick-help input', () {
      final reply = nav.detectSocialIntent('how do i sell');
      expect(reply, isNull);
    });
  });
}
