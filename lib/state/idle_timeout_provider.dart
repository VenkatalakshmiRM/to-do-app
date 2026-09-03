import 'package:flutter_riverpod/legacy.dart';

class IdleTimeoutSettings {
  const IdleTimeoutSettings({
    this.enabled = true,
    this.timeout = const Duration(minutes: 30),
  });

  final bool enabled;
  final Duration timeout;

  IdleTimeoutSettings copyWith({bool? enabled, Duration? timeout}) {
    return IdleTimeoutSettings(
      enabled: enabled ?? this.enabled,
      timeout: timeout ?? this.timeout,
    );
  }
}

final idleTimeoutProvider = StateProvider<IdleTimeoutSettings>(
  (ref) => const IdleTimeoutSettings(),
);
