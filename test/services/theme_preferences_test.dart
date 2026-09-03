import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_task_hub/services/theme_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and restores the selected theme mode', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await ThemePreferences.loadThemeMode(), ThemeMode.system);

    await ThemePreferences.saveThemeMode(ThemeMode.dark);

    expect(await ThemePreferences.loadThemeMode(), ThemeMode.dark);
  });
}
