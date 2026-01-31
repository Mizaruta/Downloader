import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:modern_downloader/core/providers/launch_provider.dart';
import 'package:modern_downloader/core/providers/settings_provider.dart';
import 'package:modern_downloader/features/downloader/domain/repositories/i_downloader_repository.dart';
import 'package:modern_downloader/features/downloader/domain/entities/download_item.dart';
import 'package:modern_downloader/features/downloader/presentation/providers/downloader_provider.dart';
import '../logger/logger_service.dart';
import '../services/notification_service.dart';

final localServerServiceProvider = Provider<LocalServerService>((ref) {
  return LocalServerService(ref);
});

class LocalServerService {
  final Ref _ref;
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  LocalServerService(this._ref);

  Future<void> start() async {
    final settings = _ref.read(settingsProvider);
    final port = settings.serverPort;

    // Listen to repository updates to broadcast progress
    _ref.listen<IDownloaderRepository>(downloaderRepositoryProvider, (
      previous,
      next,
    ) {
      // Monitor the stream manually since the provider returns the Repo instance
    });

    // Better: We need to listen to the *stream* exposed by the repository
    final repo = _ref.read(downloaderRepositoryProvider);
    repo.downloadUpdateStream.listen(_broadcastProgress);

    try {
      // Revert to 127.0.0.1 to check if Firewall was blocking 0.0.0.0
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      LoggerService.i('''
==================================================
🚀 Local Server running on http://localhost:$port
🔌 WebSocket Mode: ENABLED (Zero-Config)
✅ Ready for Extension Connection
==================================================
''');

      _server!.listen((HttpRequest request) {
        _handleRequest(request);
      });
    } catch (e) {
      LoggerService.e('Failed to start Local Server on port $port', e);
    }
  }

  Future<void> stop() async {
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // 1. WebSocket Upgrade Key
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocket(socket, request);
      } catch (e) {
        LoggerService.e('WebSocket upgrade failed', e);
      }
      return;
    }

    // 2. Fallback / Status for HTTP (Legacy/Health check)
    request.response.headers.add('Access-Control-Allow-Origin', '*');

    if (request.uri.path == '/status') {
      request.response.write(
        jsonEncode({'status': 'running', 'mode': 'websocket'}),
      );
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }

  void _handleWebSocket(WebSocket socket, HttpRequest request) {
    LoggerService.i(
      '🔌 Extension Connected (WebSocket) from ${request.connectionInfo?.remoteAddress.address}',
    );
    NotificationService().showExtensionConnected();
    _clients.add(socket);

    socket.listen(
      (message) {
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          final type = data['type'] as String?;

          if (type == 'PING') {
            socket.add(jsonEncode({'type': 'PONG'}));
            return;
          }

          if (type == 'HELLO') {
            LoggerService.i('👋 Extension Hello received');
            return;
          }

          if (type == 'DEBUG') {
            LoggerService.i('🐛 EXT DEBUG: ${data['message']}');
            return;
          }

          if (type == 'DOWNLOAD') {
            _processDownloadPayload(data);
            socket.add(
              jsonEncode({'type': 'ACK', 'message': 'Download received'}),
            );
          } else if (type == 'HEARTBEAT_COOKIES') {
            _handleHeartbeatCookies(data);
          }
        } catch (e) {
          LoggerService.e('Error parsing WS message', e);
        }
      },
      onDone: () {
        LoggerService.i('🔌 Extension Disconnected');
        _clients.remove(socket);
      },
      onError: (e) {
        LoggerService.e('WebSocket Error', e);
        _clients.remove(socket);
      },
    );
  }

  void _broadcastProgress(DownloadItem item) {
    if (_clients.isEmpty) return;

    // We only send significant updates or summarize
    // Ideally we should send a list of active downloads, but sending individual updates is easier for now
    // The extension will simply upsert this item in its list

    final payload = jsonEncode({'type': 'PROGRESS', 'data': item.toJson()});

    // Broadcast to all
    for (final client in _clients) {
      if (client.readyState == WebSocket.open) {
        client.add(payload);
      }
    }
  }

  Future<void> _handleHeartbeatCookies(Map<String, dynamic> data) async {
    // Save cookies to a central file for general usage
    // This allows the app to use these cookies even if the link didn't come from the extension
    try {
      final domain = data['domain'] as String?;
      final cookies = data['cookies'] as String?;
      if (cookies != null && domain != null) {
        // VALIDATION: yt-dlp --cookies requires Netscape format (7 tab-separated columns)
        // If we receive a simple "key=value; ..." header string, we must NOT save it as a .txt file passed to --cookies.
        // Doing so causes yt-dlp to error out and fail downloads.
        if (!cookies.contains('\t') && cookies.contains('=')) {
          LoggerService.w(
            '❤️ Heartbeat: Received cookies for $domain in Header format (not Netscape). Ignoring to prevent yt-dlp errors.',
          );
          return;
        }

        final appDir = Directory.systemTemp; // Or specialized cache dir
        final cookieFile = File('${appDir.path}/heartbeat_cookies.txt');
        await cookieFile.writeAsString(cookies);
        LoggerService.i('❤️ Heartbeat: Updated cookies for $domain');

        // Update settings to point to this file
        _ref
            .read(settingsProvider.notifier)
            .setCookiesFilePath(cookieFile.path);
      }
    } catch (e) {
      LoggerService.e('Failed to handle heartbeat cookies', e);
    }
  }

  void _processDownloadPayload(Map<String, dynamic> data) {
    final url = data['url'] as String?;
    final cookies = data['cookies'] as String?;
    final userAgent = data['userAgent'] as String?;

    // New Param Support
    final isAudioOnly = data['isAudioOnly'] as bool?;
    final isPlaylist = data['isPlaylist'] as bool?;
    final cookieBrowser = data['cookieBrowser'] as String?;

    if (url != null) {
      LoggerService.i('📥 Received download request: $url');
      if (cookies != null) {
        LoggerService.debug('With Cookies: ${cookies.length} chars');
      }

      if (isPlaylist == true) {
        LoggerService.i('Playlist Mode Detected');
      }

      if (userAgent != null) {
        LoggerService.debug('With UA: $userAgent');
      }

      if (isAudioOnly == true) {
        _ref.read(settingsProvider.notifier).setAudioOnly(true);
      }

      // SIMPLIFIED MODE: Ignore extension cookies/UA as per user request
      // The app will use its internal settings or cookies file
      // UPDATE: Pass cookieBrowser if provided by extension
      _ref.read(launchDataProvider.notifier).state = LaunchData(
        url: url,
        cookies: null, // Force null
        userAgent: null, // Force null
        isAudioOnly: isAudioOnly ?? false,
        shouldAutoStart: true, // Extensions want instant start
        isPlaylist: isPlaylist ?? false,
        cookieBrowser: cookieBrowser,
      );

      // Bring window to front
      windowManager.show();
      windowManager.focus();

      NotificationService().showClipboardDetected(url);
    }
  }
}
