import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dialpad/dialpad_screen.dart';
import '../features/recents/recents_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/in_call/in_call_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dialpad',
  routes: [
    // ── In-call full-screen (no bottom nav) ──────────────────────────────
    GoRoute(
      path: '/incall',
      builder: (context, state) {
        final extra = state.extra as Map<String, String?>? ?? {};
        return InCallScreen(
          callerNumber: extra['number'] ?? '',
          callerName:   extra['name'],
        );
      },
    ),

    // ── Main shell with bottom nav ───────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dialpad',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DialpadScreen()),
        ),
        GoRoute(
          path: '/recents',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecentsScreen()),
        ),
        GoRoute(
          path: '/contacts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ContactsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);
