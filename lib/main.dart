import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/idle_timeout_preferences.dart';
import 'services/supabase_service.dart';
import 'services/theme_preferences.dart';
import 'state/theme_provider.dart';
import 'state/idle_timeout_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initialize();
  final supabaseInitialized = await SupabaseService.initialize();
  final initialThemeMode = await ThemePreferences.loadThemeMode();
  final idleLogoutEnabled = await IdleTimeoutPreferences.loadEnabled();

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => initialThemeMode),
        idleTimeoutProvider.overrideWith(
          (ref) => IdleTimeoutSettings(enabled: idleLogoutEnabled),
        ),
      ],
      child: App(supabaseEnabled: supabaseInitialized),
    ),
  );
}
