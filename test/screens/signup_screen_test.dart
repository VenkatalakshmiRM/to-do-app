import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/screens/auth/signup_screen.dart';

void main() {
  testWidgets('renders signup fields and validates matching passwords', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(find.byKey(const ValueKey('signup-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-password-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('signup-confirm-password-field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-field')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-confirm-password-field')),
      'secret2',
    );
    await tester.tap(find.byKey(const ValueKey('signup-submit-button')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('verification screen explains email confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmailVerificationScreen(email: 'student@example.com'),
      ),
    );

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('student@example.com'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });
}
