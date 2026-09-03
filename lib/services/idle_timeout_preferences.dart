import 'package:shared_preferences/shared_preferences.dart';

abstract final class IdleTimeoutPreferences {
  static const _enabledKey = 'idle_auto_logout_enabled';

  static Future<bool> loadEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? true;
  }

  static Future<void> saveEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }
}
