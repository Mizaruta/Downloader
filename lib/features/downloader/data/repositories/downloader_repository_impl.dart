import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/enums/download_status.dart';
import '../../domain/repositories/i_downloader_repository.dart';
import '../sources/yt_dlp_source.dart';
import '../sources/hitomi_source.dart';
import '../../../../core/logger/logger_service.dart';

class DownloaderRepositoryImpl implements IDownloaderRepository {
  final YtDlpSource _source;
  final HitomiSource _hitomiSource;
  final _controller = StreamController<DownloadItem>.broadcast();
  final _activeDownloads = <String, DownloadItem>{};

  DownloaderRepositoryImpl(this._source, this._hitomiSource);

  @override
  Stream<DownloadItem> get downloadUpdateStream => _controller.stream;

  @override
  Future<String> startDownload(DownloadRequest request) async {
    final id = const Uuid().v4();
    LoggerService.i('Starting download: ${request.url}');

    // Extract video ID or domain for initial display
    String initialTitle = _extractInitialTitle(request.url);

    final item = DownloadItem(id: id, request: request, title: initialTitle);
    _update(item);

    _startDownloadProcess(id, request);
    return id;
  }

  String _extractInitialTitle(String url) {
    // Extract something meaningful from URL
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube Video';
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return 'Twitter Video';
    } else if (url.contains('twitch.tv')) {
      return 'Twitch Video';
    } else if (url.contains('tiktok.com')) {
      return 'TikTok Video';
    }
    return 'Video';
  }

  Future<void> _startDownloadProcess(String id, DownloadRequest request) async {
    try {
      LoggerService.debug('Download $id: Extracting info...');
      _update(
        _activeDownloads[id]!.copyWith(status: DownloadStatus.extracting),
      );

      LoggerService.debug('Download $id: Starting download...');
      _update(
        _activeDownloads[id]!.copyWith(status: DownloadStatus.downloading),
      );

      await for (final progress in _source.download(id, request)) {
        _update(
          _activeDownloads[id]!.copyWith(
            progress: progress.progress,
            eta: progress.eta,
            speed: progress.speed,
            title:
                progress.title ??
                _activeDownloads[id]!.title, // Update title if available
          ),
        );
      }

      LoggerService.i('Download $id: Completed!');
      _update(
        _activeDownloads[id]!.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
        ),
      );
    } catch (e, stackTrace) {
      LoggerService.e('Download $id FAILED with yt-dlp', e, stackTrace);

      // === HITOMI FALLBACK ===
      if (HitomiSource.shouldUseFallback(request.url)) {
        LoggerService.i('Download $id: Trying Hitomi-Downloader fallback...');
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.extracting,
            error: null, // Clear previous error
          ),
        );

        try {
          await _tryHitomiFallback(id, request);
          return; // Success with fallback
        } catch (hitomiError, hitomiStack) {
          LoggerService.e(
            'Hitomi fallback also failed',
            hitomiError,
            hitomiStack,
          );
          // Fall through to mark as failed
        }
      }

      _update(
        _activeDownloads[id]!.copyWith(
          status: DownloadStatus.failed,
          error: e.toString(),
        ),
      );
    }
  }

  /// Attempt download via Hitomi-Downloader
  Future<void> _tryHitomiFallback(String id, DownloadRequest request) async {
    _update(
      _activeDownloads[id]!.copyWith(
        status: DownloadStatus.downloading,
        title: '${_activeDownloads[id]!.title} (Hitomi)',
      ),
    );

    await for (final progress in _hitomiSource.download(id, request)) {
      if (progress.isComplete) {
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
          ),
        );
      } else {
        // Hitomi doesn't provide percentage, show time elapsed
        _update(
          _activeDownloads[id]!.copyWith(
            eta: '${progress.elapsedSeconds}s',
            speed: progress.status,
          ),
        );
      }
    }
  }

  @override
  Future<void> cancelDownload(String id) async {
    await _source.cancel(id);
    await _hitomiSource.cancel(id);
    _update(_activeDownloads[id]!.copyWith(status: DownloadStatus.canceled));
  }

  @override
  Future<void> pauseDownload(String id) async {
    await cancelDownload(id);
  }

  @override
  Future<void> resumeDownload(String id) async {
    // Logic to resume
  }

  void _update(DownloadItem item) {
    _activeDownloads[item.id] = item;
    _controller.add(item);
  }
}
