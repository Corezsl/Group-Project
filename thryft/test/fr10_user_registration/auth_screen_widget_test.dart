// Tests for FR10 (user registration & account creation) — widget tests.
// Covers AuthScreen UI: form validation, tab switching, password visibility.
// Tests 5 and 8 use mocked Supabase calls to simulate database interactions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:thryft/screens/auth_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _authApp() {
  final router = GoRouter(
    initialLocation: '/auth',
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: '/account',
        builder: (_, __) => const Scaffold(body: Text('Account Page')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const Scaffold(body: Text('Forgot Password')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

Future<void> _switchToSignUp(WidgetTester tester) async {
  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();
}

Finder _fieldByLabel(String labelText) {
  return find.ancestor(
    of: find.text(labelText),
    matching: find.byType(TextFormField),
  );
}

Future<void> _enterInto(
  WidgetTester tester, {
  required String labelText,
  required String text,
}) async {
  final field = _fieldByLabel(labelText);
  expect(field, findsOneWidget);
  await tester.enterText(field, text);
  await tester.pump();
}

bool _isObscured(WidgetTester tester, Finder textFormField) {
  final textField = find.descendant(
    of: textFormField,
    matching: find.byType(TextField),
  );
  expect(textField, findsOneWidget);
  return tester.widget<TextField>(textField).obscureText;
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final btn = find.byType(ElevatedButton);
  expect(btn, findsOneWidget);
  await tester.tap(btn);
  await tester.pump();
}

// ---------------------------------------------------------------------------
// FR10 — User registration & Account Creation
// ---------------------------------------------------------------------------

void main() {
  // Only the purely UI-specific tests remain here.

  // -------------------------------------------------------------------------
  // FR10 #2 — Tab toggle between sign up and log in
  // Input: Tap "Sign up" tab, then "Log in" tab
  // Expected: UI updates correctly — username field appears/disappears
  // -------------------------------------------------------------------------
  group('FR10 #2 — Tab toggle between sign up and log in', () {
    testWidgets('switches to sign-up mode and back to login', (tester) async {
      await tester.pumpWidget(_authApp());
      await tester.pumpAndSettle();

      // Initially in login mode — no username field
      expect(find.text('Username'), findsNothing);
      expect(find.text('Log in'), findsWidgets);

      // Switch to sign-up
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign up'), findsWidgets);

      // Switch back to log-in
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsNothing);
      expect(find.text('Confirm Password'), findsNothing);
      expect(find.text('Log in'), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // FR10 #3 — Password visibility toggle
  // Input: Tap password visibility icon
  // Expected: Password text toggles between obscured and visible states
  // -------------------------------------------------------------------------
  group('FR10 #3 — Password visibility toggle', () {
    testWidgets('toggles password field visibility', (tester) async {
      await tester.pumpWidget(_authApp());
      await tester.pumpAndSettle();

      final passwordField = _fieldByLabel('Password');
      expect(passwordField, findsOneWidget);

      expect(_isObscured(tester, passwordField), isTrue);

      final visibilityBtn = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );
      expect(visibilityBtn, findsOneWidget);
      await tester.tap(visibilityBtn);
      await tester.pump();

      expect(_isObscured(tester, passwordField), isFalse);
    });
  });
}
