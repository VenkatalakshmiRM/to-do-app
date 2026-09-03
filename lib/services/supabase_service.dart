import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_auth_storage.dart';

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

abstract final class SupabaseService {
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseConfig resolveConfig() {
    return SupabaseConfig(
      url: _definedUrl.trim().isNotEmpty
          ? _definedUrl.trim()
          : (dotenv.env['SUPABASE_URL'] ?? '').trim(),
      anonKey: _definedAnonKey.trim().isNotEmpty
          ? _definedAnonKey.trim()
          : (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim(),
    );
  }

  static Future<bool> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      final config = resolveConfig();
      if (!config.isConfigured) {
        _isInitialized = false;
        debugPrint(
          'Supabase initialization skipped: configure SUPABASE_URL and '
          'SUPABASE_ANON_KEY with --dart-define or .env.',
        );
        return false;
      }

      await Supabase.initialize(
        url: config.url,
        publishableKey: config.anonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureAuthStorage(),
        ),
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully.');
      return true;
    } catch (error, stackTrace) {
      _isInitialized = false;
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
