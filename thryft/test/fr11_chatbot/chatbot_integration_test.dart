// Tests for FR11 (chatbot) — integration tests using real Supabase.
// Verifies that chatbot navigation intent detection and routing work correctly
// with actual database operations, that auth guards block appropriately,
// and that conversations persist properly.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';

import '../helpers/supabase_test_client.dart';
import 'fr11_chatbot_test_helpers.dart';

void main() {
// Skip the integration suite when test credentials haven't been provided
if (!hasTestCredentials) {
  test(
    'FR11 chatbot integration tests',
    () {},
    skip:
        'No Supabase credentials - run '
        'flutter test --dart-define-from-file=.env.test test/fr11_chatbot',
  );
  return;
}

final ctx = Fr11ChatbotTestContext('integration');

setUpAll(ctx.setUpAll);
tearDown(ctx.tearDown);
tearDownAll(ctx.tearDownAll);

  test('Navigation with explicit verb: "Take me to my cart"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('Take me to my cart');

    expect(provider.messages.last.content, contains('cart'));
  });

  test('Navigation to protected route while logged in: "Open my account"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('Open my account');

    expect(provider.messages.last.content, contains('account'));
  });

  test('Search-with-query: "search for nike shoes"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('search for nike shoes');

    expect(provider.messages.last.content, contains('Searching for'));
    expect(provider.messages.last.content, contains('nike'));
  });

  test('General question (no navigation match): "My saved items"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('My saved items');

    expect(provider.messages.last.content, isNotEmpty);
  });

  test('Quick-help question: "How do I sell an item?"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('How do I sell an item?');

    expect(provider.messages.last.content, contains('Create Listing'));
  });

  test('Category browsing: "Browse the footwear category"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('Browse the footwear category');

    expect(provider.messages.last.content, contains('Browsing the'));
    expect(provider.messages.last.content, contains('footwear'));
  });

  test('Fuzzy spelling tolerance: "hw do i sel an itm"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('hw do i sel an itm');

    expect(provider.messages.last.content, isNotEmpty);
  });

  test('Navigation to protected route while logged out: "Go to my orders"', () async {
    final provider = AssistantChatProvider(
      chatService: ctx.chatService,
      supabase: ctx.client,
    );

    await ctx.client.auth.signOut(scope: SignOutScope.local);

    try {
      await provider.send('Go to my orders');
      expect(provider.messages.last.content, isNot(contains('orders')));
    } finally {
      await ctx.client.auth.signInWithPassword(
        email: ctx.userEmail,
        password: fr11TestPassword,
      );
    }
  });

  test('Empty/whitespace-only message: "   "', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('   ');

    expect(provider.messages.last.content, isNot(contains('Browsing the')));
  });

  test('Unknown category: "Browse the electronics category"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('Browse the electronics category');

    expect(provider.messages.last.content, isNot(contains('Browsing the')));
  });

  test('Low-confidence ambiguous input (no nav-verb): "I love shopping"', () async {
    final provider = await ctx.createChatProvider();

    await provider.send('I love shopping');

    expect(provider.messages.last.content, isNot(contains('Browsing the')));
    expect(provider.messages.last.content, isNot(contains('Searching for')));
  });
}

