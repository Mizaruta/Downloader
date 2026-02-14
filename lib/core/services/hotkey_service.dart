import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../../features/downloader/presentation/views/dialogs/add_download_dialog.dart';
import '../logger/logger_service.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global keyboard shortcuts handler.
/// Wraps the app shell to intercept key events.
class HotkeyHandler extends ConsumerWidget {
  final Widget child;

  const HotkeyHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _handleKeyEvent(context, ref, event);
        }
      },
      child: child,
    );
  }

  void _handleKeyEvent(
    BuildContext context,
    WidgetRef ref,
    KeyDownEvent event,
  ) {
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Ctrl+N → New Download
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      LoggerService.debug('Hotkey: Ctrl+N → New Download');
      showDialog(
        context: context,
        builder: (context) => const AddDownloadDialog(),
      );
      return;
    }

    // Ctrl+, → Settings
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.comma) {
      LoggerService.debug('Hotkey: Ctrl+, → Settings');
      context.go('/settings/general');
      return;
    }

    // Ctrl+D → Statistics Dashboard
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
      LoggerService.debug('Hotkey: Ctrl+D → Statistics');
      context.go('/stats');
      return;
    }

    // Escape → Minimize to tray (if enabled)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final settings = ref.read(settingsProvider);
      if (settings.minimizeToTray) {
        LoggerService.debug('Hotkey: Esc → Minimize to tray');
        windowManager.hide();
      } else {
        windowManager.minimize();
      }
      return;
    }
  }
}
