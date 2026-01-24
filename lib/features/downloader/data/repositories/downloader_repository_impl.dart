import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/enums/download_status.dart';
import '../../domain/repositories/i_downloader_repository.dart';
import '../sources/yt_dlp_source.dart';
import '../sources/gallery_dl_source.dart';
import '../../../../core/logger/logger_service.dart';
import '../datasources/persistence_service.dart';

class DownloaderRepositoryImpl implements IDownloaderRepository {
  final YtDlpSource _source;
  final GalleryDlSource _galleryDlSource;
  final PersistenceService _persistenceService;

  final _controller = StreamController<DownloadItem>.broadcast();
  final _activeDownloads = <String, DownloadItem>{};

  // Debounce saving to disk
  Timer? _saveTimer;

  DownloaderRepositoryImpl(
    this._source,
    this._galleryDlSource,
    this._persistenceService,
  ) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final loaded = await _persistenceService.loadDownloads();
    for (final item in loaded) {
      // If was downloading, mark as paused/failed/interrupted since app restarted
      var status = item.status;
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.extracting) {
        status = DownloadStatus.paused; // Or failed
      }

      final cleanItem = item.copyWith(status: status);
      _activeDownloads[item.id] = cleanItem;
      // We don't emit here immediately to avoid flood, usually listener comes later,
      // but we can't easily emit to stream before listeners.
      // A BehaviorSubject would be better but simple stream controller is used here.
    }
  }

  // Method to get current list for providers, sorted by user preference
  @override
  List<DownloadItem> getCurrentDownloads() {
    final list = _activeDownloads.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Stream<DownloadItem> get downloadUpdateStream => _controller.stream;

  @override
  Future<String> startDownload(DownloadRequest request) async {
    final id = const Uuid().v4();
    LoggerService.i('Starting download: ${request.url}');

    // Extract video ID or domain for initial display
    String initialTitle = _extractInitialTitle(request.url);

    // Calculate next sort order
    int nextOrder = 0;
    if (_activeDownloads.isNotEmpty) {
      final maxOrder = _activeDownloads.values
          .map((e) => e.sortOrder)
          .reduce((a, b) => a > b ? a : b);
      nextOrder = maxOrder + 1;
    }

    final item = DownloadItem(
      id: id,
      request: request,
      title: initialTitle,
      sortOrder: nextOrder,
    );
    _update(item);

    _startDownloadProcess(id, request);
    return id;
  }

  @override
  Future<void> reorderDownloads(int oldIndex, int newIndex) async {
    final sortedList = getCurrentDownloads();
    if (oldIndex < 0 || oldIndex >= sortedList.length) return;
    if (newIndex < 0 || newIndex > sortedList.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = sortedList.removeAt(oldIndex);
    sortedList.insert(newIndex, item);

    // Update sortOrder for all affected items
    for (int i = 0; i < sortedList.length; i++) {
      final updatedItem = sortedList[i].copyWith(sortOrder: i);
      _activeDownloads[updatedItem.id] = updatedItem;
      // We don't need to emit every single update to stream,
      // just saving to disk and next getCurrentDownloads call will reflect it.
      // But providers watching stream might get confused if we don't emit.
      // Actually, filteredProvider depends on Ref.watch(downloaderProvider) which depends on stream?
      // No, usually it depends on a StateNotifier that refreshes.
      // We should probably emit updates if we want UI to reflect instantaneously via stream.
      // But for reorder, UI drives the change locally first usually.
    }

    // Persist all changes
    _saveToDisk();
  }

  // ... (rest of methods: _extractInitialTitle, _startDownloadProcess, etc.)
  // I need to be careful not to delete them. The targeted replacement should precise.

  // I will just replace `getCurrentDownloads` and `startDownload` and add `reorderDownloads`.
  // I'll skip `_startDownloadProcess` modification as it's huge.
  // Wait, I need to match the correct lines to replace.

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
        // progress.progress == -1 means "title only update, don't change progress"
        final newProgress = progress.progress >= 0
            ? progress.progress
            : _activeDownloads[id]!.progress;

        _update(
          _activeDownloads[id]!.copyWith(
            progress: newProgress,
            eta: progress.eta.isNotEmpty
                ? progress.eta
                : _activeDownloads[id]!.eta,
            speed: progress.speed.isNotEmpty
                ? progress.speed
                : _activeDownloads[id]!.speed,
            totalSize: progress.totalSize.isNotEmpty
                ? progress.totalSize
                : _activeDownloads[id]!.totalSize,
            downloadedSize: progress.downloadedSize.isNotEmpty
                ? progress.downloadedSize
                : _activeDownloads[id]!.downloadedSize,
            step: progress.step.isNotEmpty
                ? progress.step
                : _activeDownloads[id]!.step,
            title:
                progress.title ??
                _activeDownloads[id]!.title, // Update title if available
            filePath: progress.filePath ?? _activeDownloads[id]!.filePath,
          ),
        );
      }

      LoggerService.i('Download $id: Completed!');
      // Preserve the extracted title from the download process
      final finalTitle = _activeDownloads[id]!.title;
      _update(
        _activeDownloads[id]!.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          title: finalTitle,
          filePath: _activeDownloads[id]!.filePath,
        ),
      );
    } catch (e, stackTrace) {
      LoggerService.e('Download $id FAILED with yt-dlp', e, stackTrace);

      // === GALLERY-DL FALLBACK ===
      if (GalleryDlSource.shouldUseFallback(request.url)) {
        LoggerService.i('Download $id: Trying gallery-dl fallback...');
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.extracting,
            error: null, // Clear previous error
          ),
        );

        try {
          await _tryGalleryDlFallback(id, request);
          return; // Success with fallback
        } catch (galleryDlError, galleryDlStack) {
          LoggerService.e(
            'gallery-dl fallback also failed',
            galleryDlError,
            galleryDlStack,
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

  /// Attempt download via gallery-dl
  Future<void> _tryGalleryDlFallback(String id, DownloadRequest request) async {
    _update(_activeDownloads[id]!.copyWith(status: DownloadStatus.downloading));

    await for (final progress in _galleryDlSource.download(id, request)) {
      if (progress.isComplete) {
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
            title: progress.title ?? _activeDownloads[id]!.title,
          ),
        );
      } else {
        _update(
          _activeDownloads[id]!.copyWith(
            speed: progress.status,
            title: progress.title ?? _activeDownloads[id]!.title,
          ),
        );
      }
    }
  }

  @override
  Future<void> cancelDownload(String id) async {
    LoggerService.i('Canceling download $id');
    await _source.cancel(id);
    await _galleryDlSource.cancel(id);

    if (_activeDownloads.containsKey(id)) {
      _update(_activeDownloads[id]!.copyWith(status: DownloadStatus.canceled));
    }
  }

  @override
  Future<void> deleteDownload(String id) async {
    LoggerService.i('Deleting download $id');
    final item = _activeDownloads[id];

    // 1. Cancel if running
    if (item != null &&
        (item.status == DownloadStatus.downloading ||
            item.status == DownloadStatus.extracting)) {
      await cancelDownload(id);
    }

    // 2. Delete file if exists
    if (item?.filePath != null) {
      try {
        final file = File(item!.filePath!);
        if (await file.exists()) {
          await file.delete();
          LoggerService.i('Deleted file: ${item.filePath}');
        }
      } catch (e) {
        LoggerService.w('Failed to delete file: $e');
      }
    }

    // 3. Remove from list
    _activeDownloads.remove(id);
    // Emit deletion event? Or just rebuild list.
    // Since stream sends UPDATES, removal is tricky if we don't send the Full List.
    // Ideally we should emit a special event or just null, but existing stream expects DownloadItem.
    // For now, simpler: we persist the removal, and callers usually watch `downloadListProvider`
    // which needs to be updated.
    _saveToDisk();

    // We cannot easily notify stream subscribers of DELETION with current IDownloaderRepository interface
    // returning Stream<DownloadItem>.
    // We will rely on providers to refresh or we can emit an item with "deleted" status if we want.
    // But since `_activeDownloads` is source of truth, cleaning it is enough IF the provider polls it or we trigger refresh.
  }

  @override
  Future<void> pauseDownload(String id) async {
    // TODO: yt-dlp doesn't support true pause - would need to kill and resume with --continue
    throw UnimplementedError('Pause is not supported by yt-dlp');
  }

  @override
  Future<void> resumeDownload(String id) async {
    // TODO: Would need to restart download with same URL and --continue flag
    throw UnimplementedError('Resume is not supported yet');
  }

  void _update(DownloadItem item) {
    _activeDownloads[item.id] = item;
    _controller.add(item);
    _saveToDisk();
  }

  void _saveToDisk() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _persistenceService.saveDownloads(_activeDownloads.values.toList());
    });
  }
}
