import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/screens/auth/login_screen.dart';

void main() {
  testWidgets('shows email and Google sign-in options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Campus To-Do'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('email-sign-in-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('apple-sign-in-button')), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('validates email format and minimum password length', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('login-email-field')),
      'invalid-email',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      '12345',
    );
    await tester.tap(find.byKey(const ValueKey('email-sign-in-button')));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('forgot password opens the recovery form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.byKey(const ValueKey('forgot-password-button')));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Password recovery'), findsOneWidget);
  });
}
