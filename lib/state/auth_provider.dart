import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// The authenticated Supabase session, kept current for the lifetime of the app.
///
/// Supabase emits the restored session first and then every subsequent sign-in,
/// token refresh, and sign-out event.
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  if (!SupabaseService.isInitialized) {
    yield null;
    return;
  }

  final auth = Supabase.instance.client.auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange
      .map((event) => event.session)
      .distinct(
        (previous, next) =>
            previous?.accessToken == next?.accessToken &&
            previous?.user.id == next?.user.id,
      );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authSessionProvider).value?.user;
});
