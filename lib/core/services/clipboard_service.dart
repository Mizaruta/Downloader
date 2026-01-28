import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logger/logger_service.dart';
import '../providers/settings_provider.dart';

// Provider for easy access
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return ClipboardService(ref);
});

class ClipboardService {
  final Ref _ref;
  Timer? _timer;
  String? _lastContent;

  final _controller = StreamController<String>.broadcast();
  Stream<String> get clipboardStream => _controller.stream;

  ClipboardService(this._ref);

  void startMonitoring() async {
    _stopMonitoring(); // Ensure no duplicates

    // Initialize with current content to avoid immediate notification on startup
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _lastContent = data.text!.trim();
    }

    // Poll every 2 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkClipboard(),
    );
    LoggerService.i('Clipboard monitoring started');
  }

  void stopMonitoring() {
    _stopMonitoring();
    LoggerService.i('Clipboard monitoring stopped');
  }

  void _stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkClipboard() async {
    // Check if monitoring is enabled in settings
    final enabled = _ref.read(settingsProvider).clipboardMonitorEnabled;
    if (!enabled) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data == null || data.text == null) return;

      final content = data.text!.trim();

      // Optimization: Don't re-process the same content
      if (content == _lastContent) return;
      _lastContent = content;

      if (_isValidUrl(content)) {
        LoggerService.debug('Clipboard match found: $content');
        _controller.add(content);
      }
    } catch (e) {
      // Ignore platform channel errors
    }
  }

  bool _isValidUrl(String text) {
    if (text.isEmpty) return false;

    // Basic supported domains check
    final supported = [
      'youtube.com',
      'youtu.be',
      'twitter.com',
      'x.com',
      'instagram.com',
      'twitch.tv',
      'tiktok.com',
      'kick.com',
      'vimeo.com',
      'dailymotion.com',
      'facebook.com',
      'reddit.com',
      'soundcloud.com',
    ];

    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      return false;
    }

    return supported.any((domain) => text.contains(domain));
  }
}
