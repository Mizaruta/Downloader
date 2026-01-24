import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'core/config/app_config.dart';
import 'core/platform/platform_info.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:modern_downloader/core/services/single_instance_service.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:modern_downloader/core/providers/launch_provider.dart';
import 'dart:io'; // Required for exit(0)

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences BEFORE anything else
  final prefsInstance = await SharedPreferences.getInstance();
  initPrefs(prefsInstance); // Initialize global prefs holder

  // Protocol Handler Setup
  await protocolHandler.register('moderndownloader');

  // Single Instance Check (especially for Windows via Browser Extension)
  final container = ProviderContainer();
  final alreadyRunning = await SingleInstanceService.check(args, container);
  if (alreadyRunning) {
    debugPrint('App already running. Terminating this instance.');
    exit(0);
  }

  String? initialUrl;

  // Try to get initial URI from protocol_handler (cold start from link)
  final initialUrlStr = await protocolHandler.getInitialUrl();
  if (initialUrlStr != null) {
    initialUrl = _extractUrlFromUri(initialUrlStr);
  }

  // Fallback to command line args if protocol_handler didn't catch it
  if (initialUrl == null && args.isNotEmpty) {
    final protocolArg = args.firstWhere(
      (arg) => arg.contains('moderndownloader://'),
      orElse: () => '',
    );
    if (protocolArg.isNotEmpty) {
      initialUrl = _extractUrlFromUri(protocolArg);
    }
  }

  if (initialUrl != null) {
    container.read(launchUrlProvider.notifier).state = initialUrl;
  }

  if (PlatformInfo.isDesktop) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(AppConfig.initialWindowWidth, AppConfig.initialWindowHeight),
      minimumSize: Size(AppConfig.minWindowWidth, AppConfig.minWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Listen for deep links while the app is running
  protocolHandler.addListener(_ProtocolListener(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ModernDownloaderApp(),
    ),
  );
}

String? _extractUrlFromUri(String uriString) {
  try {
    final uri = Uri.parse(uriString);
    if (uri.queryParameters.containsKey('url')) {
      return uri.queryParameters['url'];
    }
    // Handle cases where the URL is the host or path (depending on browser/OS behavior)
    if (uri.host == 'open' && uri.queryParameters.containsKey('url')) {
      return uri.queryParameters['url'];
    }
  } catch (e) {
    debugPrint('Error parsing URI: $e');
  }
  return null;
}

class _ProtocolListener extends ProtocolListener {
  final ProviderContainer container;
  _ProtocolListener(this.container);

  @override
  void onProtocolUrlReceived(String url) {
    final extractedUrl = _extractUrlFromUri(url);
    if (extractedUrl != null) {
      container.read(launchUrlProvider.notifier).state = extractedUrl;
      // Focus window when link received
      windowManager.show();
      windowManager.focus();
    }
  }
}

class ModernDownloaderApp extends ConsumerWidget {
  const ModernDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    ThemeMode themeMode;
    switch (settings.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme
          .lightTheme, // Need lightTheme definition or just use dark if only one
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
