import 'package:local_notifier/local_notifier.dart';
import '../logger/logger_service.dart';
import '../providers/settings_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    try {
      await localNotifier.setup(
        appName: 'Modern Downloader',
        // The parameter shortcutPolicy argument is only available on Windows
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      LoggerService.i('NotificationService initialized');
    } catch (e) {
      LoggerService.e('Failed to initialize NotificationService', e);
    }
  }

  Future<void> showDownloadComplete(String title) async {
    _show(title: 'Download Completed', body: title);
  }

  Future<void> showDownloadFailed(String title, String error) async {
    _show(title: 'Download Failed', body: '$title\n$error');
  }

  Future<void> showClipboardDetected(String url) async {
    _show(title: 'Link Detected', body: 'Click to download: $url');
  }

  Future<void> showExtensionConnected() async {
    _show(
      title: 'Extension Connected',
      body: 'Browser extension successfully connected.',
    );
  }

  Future<void> _show({required String title, required String body}) async {
    try {
      // Access prefs directly since NotificationService is a singleton
      try {
        final dnd = prefs.getBool('do_not_disturb') ?? false;
        if (dnd) {
          LoggerService.debug('DND active: suppressing notification: $title');
          return;
        }
      } catch (_) {}

      final notification = LocalNotification(title: title, body: body);

      // We can add onClick listeners here if needed in the future

      await notification.show();
    } catch (e) {
      LoggerService.w('Failed to show notification: $e');
    }
  }
}
