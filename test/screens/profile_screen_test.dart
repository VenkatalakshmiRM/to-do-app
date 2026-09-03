import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_task_hub/app.dart';
import 'package:student_task_hub/services/idle_timeout_preferences.dart';
import 'package:student_task_hub/state/idle_timeout_provider.dart';
import 'package:student_task_hub/state/theme_provider.dart';

void main() {
  testWidgets('changes the app theme from Profile settings', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('toggles and persists idle auto-logout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('idle-logout-toggle'));
    await tester.ensureVisible(toggle);
    expect(container.read(idleTimeoutProvider).enabled, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(container.read(idleTimeoutProvider).enabled, isFalse);
    expect(await IdleTimeoutPreferences.loadEnabled(), isFalse);
  });
}
