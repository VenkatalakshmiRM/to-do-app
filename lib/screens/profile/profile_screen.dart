import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../services/idle_timeout_preferences.dart';
import '../../state/idle_timeout_provider.dart';
import '../../services/theme_preferences.dart';
import '../../state/theme_provider.dart';
import '../../widgets/comic_panel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final idleTimeout = ref.watch(idleTimeoutProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Make Campus To-Do feel like yours.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        ComicPanel(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SettingsIcon(icon: Icons.palette_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text('Choose light, dark, or device settings.'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SegmentedButton<ThemeMode>(
                  key: const ValueKey('theme-mode-selector'),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_brightness_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    final selectedMode = selection.first;
                    ref.read(themeModeProvider.notifier).state = selectedMode;
                    unawaited(ThemePreferences.saveThemeMode(selectedMode));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ComicPanel(
          child: SwitchListTile(
            key: const ValueKey('idle-logout-toggle'),
            secondary: const _SettingsIcon(icon: Icons.timer_outlined),
            title: const Text('Auto-logout when idle'),
            subtitle: Text(
              'Sign out after ${idleTimeout.timeout.inMinutes} minutes in the background.',
            ),
            value: idleTimeout.enabled,
            onChanged: (enabled) {
              ref.read(idleTimeoutProvider.notifier).state = idleTimeout
                  .copyWith(enabled: enabled);
              unawaited(IdleTimeoutPreferences.saveEnabled(enabled));
            },
          ),
        ),
        const SizedBox(height: 16),
        ComicPanel(
          child: ListTile(
            leading: const _SettingsIcon(icon: Icons.logout_rounded),
            title: const Text('Sign out'),
            subtitle: SupabaseService.isInitialized
                ? null
                : const Text('Available when Supabase is configured'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: SupabaseService.isInitialized
                ? () async {
                    await Supabase.instance.client.auth.signOut(
                      scope: SignOutScope.local,
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(height: 12),
        ComicPanel(
          child: ListTile(
            key: const ValueKey('global-sign-out-button'),
            leading: const _SettingsIcon(icon: Icons.devices_outlined),
            title: const Text('Sign out of all devices'),
            subtitle: SupabaseService.isInitialized
                ? const Text('Revoke this account’s sessions on every device.')
                : const Text('Available when Supabase is configured'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: SupabaseService.isInitialized
                ? () => _signOutAllDevices(context)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _signOutAllDevices(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'You will need to sign in again on this and every other device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    } on AuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sign out all devices: $error')),
        );
      }
    }
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }
}
