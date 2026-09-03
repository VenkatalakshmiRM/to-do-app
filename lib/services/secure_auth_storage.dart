import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the serialized Supabase session in OS-backed encrypted storage.
class SecureAuthStorage extends LocalStorage {
  SecureAuthStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {
    // Migrate and remove a session written by Supabase's former default
    // SharedPreferencesLocalStorage so existing users are not signed out and
    // the plaintext copy does not remain behind.
    if (await _storage.containsKey(key: supabasePersistSessionKey)) return;
    final preferences = await SharedPreferences.getInstance();
    final previousSession = preferences.getString(supabasePersistSessionKey);
    if (previousSession == null) return;
    await _storage.write(
      key: supabasePersistSessionKey,
      value: previousSession,
    );
    await preferences.remove(supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() =>
      _storage.read(key: supabasePersistSessionKey);

  @override
  Future<bool> hasAccessToken() =>
      _storage.containsKey(key: supabasePersistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) => _storage.write(
    key: supabasePersistSessionKey,
    value: persistSessionString,
  );

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: supabasePersistSessionKey);
}
