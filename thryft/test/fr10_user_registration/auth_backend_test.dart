import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/repositories/auth_repository.dart';
import 'package:thryft/services/auth_validation.dart';
import '../helpers/mock_supabase.dart';

class MockAuthResponse extends Mock implements AuthResponse {}

class FakeProfilesFilter extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final PostgrestTransformBuilder<Map<String, dynamic>?> transform;

  FakeProfilesFilter(this.transform);

  @override
  FakeProfilesFilter eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() => transform;
}

class FakeProfilesTransform extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? result;

  FakeProfilesTransform(this.result);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>?) onValue, {
    Function? onError,
  }) {
    return Future<Map<String, dynamic>?>.value(result).then(onValue, onError: onError);
  }
}

void main() {
  group('FR10 #1 — Successful registration', () {
    test('signs up a new user when the username is available', () async {
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final profileQB = MockSupabaseQueryBuilder();
      final profileTransform = FakeProfilesTransform(null);
      final profileFilter = FakeProfilesFilter(profileTransform);

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
      when(() => profileQB.select('id')).thenAnswer((_) => profileFilter);
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => MockAuthResponse());

      final repository = AuthRepository(client: mockClient);
      await repository.signUp(
        username: 'newuser123',
        email: 'new@example.com',
        password: 'password123',
      );

      verify(
        () => mockAuth.signUp(
          email: 'new@example.com',
          password: 'password123',
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });

  group('FR10 #4 — Form validation for empty fields', () {
    test('requires all signup fields to be filled', () {
      expect(AuthValidation.username(''), 'Please enter a username');
      expect(AuthValidation.email(''), 'Please enter your email');
      expect(AuthValidation.password(''), 'Please enter a password');
      expect(AuthValidation.confirmPassword('', 'password123'), 'Please confirm your password');
    });
  });

  group('FR10 #5 — Duplicate username registration', () {
    test('throws UsernameTakenException when username already exists', () async {
      final mockClient = MockSupabaseClient();
      final profileQB = MockSupabaseQueryBuilder();
      final profileTransform = FakeProfilesTransform({'id': 'existing'});
      final profileFilter = FakeProfilesFilter(profileTransform);
      final mockAuth = MockGoTrueClient();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
      when(() => profileQB.select('id')).thenAnswer((_) => profileFilter);

      final repository = AuthRepository(client: mockClient);

      expect(
        () => repository.signUp(
          username: 'taken_user',
          email: 'duplicate@example.com',
          password: 'TestPass123',
        ),
        throwsA(isA<UsernameTakenException>()),
      );

      verifyNever(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      );
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
      final mockClient = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final profileQB = MockSupabaseQueryBuilder();
      final profileTransform = FakeProfilesTransform(null);
      final profileFilter = FakeProfilesFilter(profileTransform);

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockClient.from('profiles')).thenAnswer((_) => profileQB);
      when(() => profileQB.select('id')).thenAnswer((_) => profileFilter);
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('Network unavailable'));

      final repository = AuthRepository(client: mockClient);

      expect(
        () => repository.signUp(
          username: 'network_test',
          email: 'net_test@example.com',
          password: 'TestPass123',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
