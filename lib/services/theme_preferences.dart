import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemePreferences {
  static const _themeModeKey = 'theme_mode';

  static Future<ThemeMode> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(_themeModeKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == savedValue) return mode;
    }
    return ThemeMode.system;
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }
}
