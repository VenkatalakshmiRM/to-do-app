import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/screens/auth/forgot_password_screen.dart';

void main() {
  testWidgets('renders email form and validates its format', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    expect(
      find.byKey(const ValueKey('forgot-password-email-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('forgot-password-email-field')),
      'invalid-email',
    );
    await tester.tap(find.byKey(const ValueKey('send-reset-email-button')));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('confirmation asks the user to check their email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForgotPasswordConfirmation(email: 'student@example.com'),
        ),
      ),
    );

    expect(find.text('Check your email for a reset link'), findsOneWidget);
    expect(find.textContaining('student@example.com'), findsOneWidget);
  });
}
