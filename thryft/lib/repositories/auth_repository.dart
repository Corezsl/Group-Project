import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    final existingProfile = await _client
        .from('profiles')
        .select('id')
        .eq('username', trimmedUsername)
        .maybeSingle();

    if (existingProfile != null) {
      throw UsernameTakenException(trimmedUsername);
    }

    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': trimmedUsername},
    );
  }
}

class UsernameTakenException implements Exception {
  final String username;
  const UsernameTakenException(this.username);

  @override
  String toString() => 'Username "$username" is already taken';
}
