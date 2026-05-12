import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/auth_repository.dart';
import 'package:thryft/services/auth_validation.dart';

import '../helpers/seed_helper.dart';
import '../helpers/supabase_test_client.dart';

void main() {
  late SupabaseClient client;
  late SupabaseClient admin;
  final createdUserIds = <String>[];

  setUpAll(() async {
    if (!hasTestCredentials) return;
    client = await getTestClient();
    admin = getServiceClient();
  });

  tearDownAll(() async {
    if (!hasTestCredentials) return;

    for (final userId in createdUserIds) {
      try {
        await admin.from('profiles').delete().eq('id', userId);
      } catch (_) {}
      try {
        await admin.auth.admin.deleteUser(userId);
      } catch (_) {}
    }

    await tearDownTestData(admin);
  });

  Future<User?> _findUserByEmail(String email) async {
    for (var page = 1; page <= 5; page++) {
      final users = await admin.auth.admin.listUsers(page: page, perPage: 1000);
      for (final user in users) {
        if (user.email == email) return user;
      }
      if (users.length < 1000) break;
    }
    return null;
  }

  String _uniqueUsername(String suffix) {
    return 'fr10_${suffix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  group('FR10 #1 — Successful registration', () {
    test('signs up a new user when the username is available', () async {
      if (!hasTestCredentials) return;

      final username = _uniqueUsername('success');
      final email = '$username@thryft-test.com';
      final repository = AuthRepository(client: client);

      try {
        await repository.signUp(
          username: username,
          email: email,
          password: 'Password123!',
        );
      } on AuthException catch (e) {
        if (e.statusCode == '429') {
          markTestSkipped('Skipped due to email rate limit (429), but passes when rate limit is disabled in the database. This is a known issue with the Supabase free tier and can be ignored for test purposes. ');
          return;
        }
        rethrow;
      }

      final createdUser = await _findUserByEmail(email);
      expect(createdUser, isNotNull);
      expect(createdUser!.email, email);
      createdUserIds.add(createdUser.id);
    });
  });

  group('FR10 #4 — Form validation for empty fields', () {
    test('requires all signup fields to be filled', () {
      expect(AuthValidation.username(''), 'Please enter a username');
      expect(AuthValidation.email(''), 'Please enter your email');
      expect(AuthValidation.password(''), 'Please enter a password');
      expect(
        AuthValidation.confirmPassword('', 'password123'),
        'Please confirm your password',
      );
    });
  });

  group('FR10 #5 — Duplicate username registration', () {
    test('throws UsernameTakenException when username already exists', () async {
      if (!hasTestCredentials) return;

      final existingUsername = _uniqueUsername('duplicate');
      await seedUser(admin, username: existingUsername);
      final repository = AuthRepository(client: client);
      final email = '${existingUsername}_new@thryft-test.local';

      expect(
        () => repository.signUp(
          username: existingUsername,
          email: email,
          password: 'Password123!',
        ),
        throwsA(isA<UsernameTakenException>()),
      );

      final duplicateUser = await _findUserByEmail(email);
      expect(duplicateUser, isNull);
    });
  });

  group('FR10 #6 — Email format validation', () {
    test('rejects invalid email formats', () {
      const invalidEmails = [
        'invalidemail.com',
        'bad@',
        'bad@example',
        'bad@@example.com',
      ];

      for (final email in invalidEmails) {
        expect(AuthValidation.email(email), 'Please enter a valid email address');
      }
    });
  });

  group('FR10 #7 — Password and confirm password mismatch', () {
    test('validates that confirm password matches password', () {
      expect(
        AuthValidation.confirmPassword('different456', 'password123'),
        'Passwords do not match',
      );
    });
  });

  group('FR10 #8 — Network / error handling', () {
    test('propagates a network exception during signup', () async {
      final offlineClient = SupabaseClient('https://invalid.supabase.co', 'invalid_key');
      final repository = AuthRepository(client: offlineClient);

      expect(
        () => repository.signUp(
          username: 'network_test',
          email: 'net_test@example.com',
          password: 'Password123!',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
