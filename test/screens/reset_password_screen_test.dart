import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_task_hub/screens/auth/reset_password_screen.dart';

void main() {
  testWidgets('renders new-password fields and validates confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('reset-password-field')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password-confirmation-field')),
      'secret2',
    );
    await tester.tap(find.byKey(const ValueKey('update-password-button')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
