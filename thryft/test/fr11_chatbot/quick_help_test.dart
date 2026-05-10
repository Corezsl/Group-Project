// Tests for FR7 (chatbot) — quick-help responses for common user questions.
// Verifies that help queries (selling, returns, app info, etc.) return
// predefined local responses without calling the backend, and that fuzzy
// spelling matching handles minor typos.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // FR7 #13 — quick-help intents return predefined local responses instantly.
  group('FR7 #13 — quick-help local replies (no backend call)', () {
    test('"how do i sell an item?" returns sell guide — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('how do i sell an item?');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('Create Listing'));
    });

    test('"how do i return something?" returns return policy — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('how do i return something?');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('return policy'));
    });

    test('"what is thryft" returns app description — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('what is thryft');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('sustainable fashion'));
    });

    test('"help" returns navigation hint — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('help');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('navigate'));
    });

    test('"cancel order" and "track order" return My Orders help — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('cancel order');
      expect(provider.messages.last.content, contains('My Orders'));

      await provider.send('track order');
      expect(provider.messages.last.content, contains('My Orders'));
      verifyNever(() => chatService.getAssistantResponse(any()));
    });
  });

  // FR7 #14 — fuzzy matching tolerates minor typos in help queries.
  group('FR7 #14 — fuzzy spelling tolerance', () {
    test('typos in "how do i sell" still match via fuzzy matching — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hw do i sel');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('Create Listing'));
    });

    test('multiple typos in "how do i return" still match — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('hw do i retun');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('return policy'));
    });

    test('typo in "thryft" app name still matches — no backend', () async {
      final provider = AssistantChatProvider(
        chatService: chatService,
        supabase: supabase,
      );

      await provider.send('what is thryyft');

      verifyNever(() => chatService.getAssistantResponse(any()));
      expect(provider.messages.last.content, contains('sustainable fashion'));
    });

    test('gibberish with no close match falls through to AI backend', () async {
      final provider = AssistantChatProvider(
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
