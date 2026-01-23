import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import '../../features/downloader/presentation/views/download_view.dart';
import '../ui/app_shell.dart';
import '../ui/settings_view.dart';

// Keys for navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DownloadView()),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
    ],
  );
});
