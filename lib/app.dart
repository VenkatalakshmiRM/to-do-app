import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/reset_password_screen.dart';
import 'services/auth_deep_link_service.dart';
import 'services/supabase_service.dart';
import 'screens/assignments/assignment_form_screen.dart';
import 'screens/assignments/assignment_list_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/tasks/task_form_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'state/theme_provider.dart';
import 'state/auth_provider.dart';
import 'state/idle_timeout_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/comic_panel.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key, this.supabaseEnabled = false});

  final bool supabaseEnabled;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  static const _titles = [
    'Home',
    'Tasks',
    'Assignments',
    'Calendar',
    'Profile',
  ];
  static const _screens = <Widget>[
    HomeScreen(),
    TaskListScreen(),
    AssignmentListScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  int _selectedIndex = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  bool _resetPasswordScreenOpen = false;
  Timer? _idleTimer;
  DateTime? _backgroundedAt;
  bool _idleLogoutInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkSubscription = AuthDeepLinkService(
      appLinks: AppLinks(),
    ).links.listen(_handleDeepLink);
    if (SupabaseService.isInitialized) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            if (state.event == AuthChangeEvent.passwordRecovery) {
              _openResetPasswordScreen();
            }
          });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    unawaited(_deepLinkSubscription?.cancel());
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen<IdleTimeoutSettings>(idleTimeoutProvider, (previous, next) {
      if (!next.enabled) {
        _idleTimer?.cancel();
        _backgroundedAt = null;
      } else if (_backgroundedAt != null) {
        _scheduleIdleLogout(next.timeout);
      }
    });
    final authSession = widget.supabaseEnabled
        ? ref.watch(authSessionProvider)
        : null;

    return MaterialApp(
      title: 'Campus To-Do',
      navigatorKey: _navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: !widget.supabaseEnabled
          ? _buildShell()
          : authSession!.when(
              loading: () => const _AuthLoadingScreen(),
              error: (error, stackTrace) => const LoginScreen(),
              data: (session) =>
                  session == null ? const LoginScreen() : _buildShell(),
            ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(idleTimeoutProvider);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (!settings.enabled || _backgroundedAt != null) return;
        _backgroundedAt = DateTime.now();
        _scheduleIdleLogout(settings.timeout);
        return;
      case AppLifecycleState.resumed:
        _idleTimer?.cancel();
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (settings.enabled &&
            backgroundedAt != null &&
            DateTime.now().difference(backgroundedAt) >= settings.timeout) {
          unawaited(_autoLogout());
        }
    }
  }

  void _scheduleIdleLogout(Duration timeout) {
    _idleTimer?.cancel();
    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null) return;
    final elapsed = DateTime.now().difference(backgroundedAt);
    final remaining = timeout - elapsed;
    if (remaining <= Duration.zero) {
      unawaited(_autoLogout());
    } else {
      _idleTimer = Timer(remaining, () => unawaited(_autoLogout()));
    }
  }

  Future<void> _autoLogout() async {
    if (_idleLogoutInProgress || !SupabaseService.isInitialized) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    _idleLogoutInProgress = true;
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } finally {
      _idleLogoutInProgress = false;
      _backgroundedAt = null;
      _idleTimer?.cancel();
    }
  }

  Widget _buildShell() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Menu',
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
        ),
        title: Text(_titles[_selectedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: switch (_selectedIndex) {
        1 => FloatingActionButton(
          onPressed: () => _open(const TaskFormScreen()),
          child: const Icon(Icons.add),
        ),
        2 => FloatingActionButton(
          onPressed: () => _open(const AssignmentFormScreen()),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ComicPanel(
          borderRadius: 6,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: _ActiveNavIcon(icon: Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.checklist_rounded),
                activeIcon: _ActiveNavIcon(icon: Icons.checklist_rounded),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: _ActiveNavIcon(icon: Icons.assignment_rounded),
                label: 'Assignments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: _ActiveNavIcon(icon: Icons.calendar_month_rounded),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: _ActiveNavIcon(icon: Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(Widget screen) {
    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _handleDeepLink(Uri uri) {
    if (AuthDeepLinkService.isPasswordRecoveryLink(uri)) {
      _openResetPasswordScreen();
    }
  }

  void _openResetPasswordScreen() {
    if (_resetPasswordScreenOpen) return;
    _resetPasswordScreenOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _resetPasswordScreenOpen = false;
        return;
      }
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
      );
      _resetPasswordScreenOpen = false;
    });
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Campus To-Do',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              key: ValueKey('auth-session-loading'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD200),
        border: Border.all(color: const Color(0xFF111111), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: const Color(0xFF111111)),
    );
  }
}
