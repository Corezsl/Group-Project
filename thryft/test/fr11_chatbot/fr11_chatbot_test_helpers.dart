import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/providers/assistant_chat_provider.dart';
import 'package:thryft/providers/chat_service.dart';

import '../helpers/seed_helper.dart';
import '../helpers/supabase_test_client.dart';

const fr11TestPassword = 'Thryft!test99';

class Fr11ChatbotTestContext {
  Fr11ChatbotTestContext(this.scope);

  final String scope;

  late SupabaseClient client;
  late SupabaseClient serviceClient;
  late String userId;
  late String userEmail;
  late ChatService chatService;

  final conversationIds = <String>[];
  final userIds = <String>[];

  String get _emailPrefix => 'fr11.$runId.$scope';

  String get _usernamePrefix {
    return 'fr11_${runId}_$scope'.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  }

  Future<void> setUpAll() async {
    client = await getTestClient();
    serviceClient = getServiceClient();
    chatService = ChatService();

    userEmail = '$_emailPrefix.user@thryft-test.local';
    userId = await ensureTestUser(
      email: userEmail,
      username: '${_usernamePrefix}_user',
    );

    await _signIn(userEmail);

    userIds.add(userId);
  }

  Future<void> tearDown() async {
    // Clean up any test data created during tests
    for (final conversationId in conversationIds) {
      try {
        await client.from('user_interactions').delete().eq('id', conversationId);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    conversationIds.clear();
  }

  Future<void> tearDownAll() async {
    await tearDown();
    
    await client.auth.signOut();
    if (userIds.isEmpty) return;

    await serviceClient.from('profiles').delete().inFilter('id', userIds);
    for (final userId in userIds) {
      try {
        await serviceClient.auth.admin.deleteUser(userId);
      } catch (_) {}
    }
  }

  Future<String> ensureTestUser({
    required String email,
    required String username,
  }) async {
    try {
      final created = await serviceClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: fr11TestPassword,
          emailConfirm: true,
          userMetadata: {'username': username},
        ),
      );
      final user = created.user;
      if (user == null) throw StateError('Could not create test user $email');

      await serviceClient.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return user.id;
    } on AuthException catch (e) {
      if (!e.message.contains('already') && !e.message.contains('registered')) {
        rethrow;
      }

      final existing = await _findUserByEmail(email);
      if (existing == null) {
        throw StateError('Test user exists but could not be found: $email');
      }

      await serviceClient.from('profiles').upsert({
        'id': existing.id,
        'username': username,
        'rating': 0.0,
        'rating_count': 0,
      });

      return existing.id;
    }
  }

  Future<User?> _findUserByEmail(String email) async {
    for (var page = 1; page <= 5; page++) {
      final users = await serviceClient.auth.admin.listUsers(
        page: page,
        perPage: 1000,
      );
      for (final user in users) {
        if (user.email == email) return user;
      }
      if (users.length < 1000) break;
    }
    return null;
  }

  Future<String> _signIn(String email) async {
    final currentUser = client.auth.currentUser;
    if (currentUser?.email == email) return currentUser!.id;

    AuthResponse res;
    try {
      res = await client.auth.signInWithPassword(
        email: email,
        password: fr11TestPassword,
      );
    } on AuthException {
      await client.auth.signOut(scope: SignOutScope.local);
      res = await client.auth.signInWithPassword(
        email: email,
        password: fr11TestPassword,
      );
    }

    return res.user!.id;
  }

  Future<AssistantChatProvider> createChatProvider() async {
    return AssistantChatProvider(
      chatService: chatService,
      supabase: client,
    );
  }

  Future<String> createConversation(String title) async {
    final conversationData = {
      'user_id': userId,
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final result = await client
        .from('conversations')
        .insert(conversationData)
        .select('id')
        .single();

    final conversationId = result['id'] as String;
    conversationIds.add(conversationId);
    return conversationId;
  }

  Future<void> sendMessage(String message) async {
    final provider = await createChatProvider();
    await provider.send(message);
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId) async {
    final result = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return result;
  }

  Future<List<Map<String, dynamic>>> getUserConversations() async {
    final result = await client
        .from('user_interactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return result;
  }
}
