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

class MockUser extends Mock implements User {}

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
// FR7 — Quick-help responses (instant, no backend call)
// ---------------------------------------------------------------------------

void main() {
  group('FR7 — quick-help instant local replies', () {
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

    test('"how do i sell an item?" returns predefined sell guide instantly', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('how do i sell an item?');

      // Never hit the AI backend.
      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Create Listing'));
      expect(last.content, contains('sell'));
    });

    test('"how do i return something?" returns return policy guide', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('how do i return something?');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('return policy'));
    });

    test('"what is thryft" returns app description', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('what is thryft');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('sustainable fashion'));
    });

    test('"help" returns navigation hint message', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('help');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('navigate'));
    });

    test('"cancel order" returns cancellation instructions', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('cancel order');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('My Orders'));
    });

    test('"track order" returns tracking instructions', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('track order');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('My Orders'));
    });
  });

  group('FR7 — fuzzy spelling tolerance', () {
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

    test('"hw do i sel" matches "how do i sell" via fuzzy matching', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hw do i sel');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Create Listing'));
    });

    test('"how do i selll an itm" tolerates multiple typos', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('how do i selll an itm');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('Create Listing'));
    });

    test('"hw do i retun" matches "how do i return" via fuzzy matching', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hw do i retun');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('return policy'));
    });

    test('"what is thryyft" tolerates typo in app name', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('what is thryyft');

      verifyNever(() => chatService.getAssistantResponse(any()));

      final last = provider.messages.last;
      expect(last.role, equals(ChatRole.assistant));
      expect(last.content, contains('sustainable fashion'));
    });

    test('gibberish with no close match falls through to backend', () async {
      final provider = _createProvider(
        chatService: chatService,
        supabase: supabase,
      );

      when(() => chatService.getAssistantResponse(any()))
          .thenAnswer((_) async => 'Here is some general info.');

      await provider.send('xyzqwe123 nonsense');

      verify(() => chatService.getAssistantResponse(any())).called(1);
    });
  });
}
