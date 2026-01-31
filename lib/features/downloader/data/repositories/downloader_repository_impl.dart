import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/enums/download_status.dart';
import '../../domain/repositories/i_downloader_repository.dart';
import '../sources/yt_dlp_source.dart';
import '../sources/gallery_dl_source.dart';
import '../services/library_scanner_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/duplicate_detector_service.dart';
import '../datasources/persistence_service.dart';
import '../../../../core/services/title_cleaner_service.dart';

class DownloaderRepositoryImpl implements IDownloaderRepository {
  final YtDlpSource _source;
  final GalleryDlSource _galleryDlSource;
  final PersistenceService _persistenceService;
  final LibraryScannerService _libraryScanner;

  final _controller = StreamController<DownloadItem>.broadcast();
  final _activeDownloads = <String, DownloadItem>{};
  Timer? _saveTimer;

  DownloaderRepositoryImpl(
    this._source,
    this._galleryDlSource,
    this._persistenceService,
    this._libraryScanner,
  ) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final loaded = await _persistenceService.loadDownloads();
    List<DownloadItem> initialList = [];

    for (final item in loaded) {
      if (_activeDownloads.containsKey(item.id)) continue;
      var status = item.status;
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.extracting) {
        status = DownloadStatus.paused;
      }
      initialList.add(item.copyWith(status: status));
    }

    // Get the download path for scanning
    final downloadPath = await _getDownloadPath();
    if (downloadPath == null) {
      // Just load items without scanning if we can't determine path
      for (final item in initialList) {
        _activeDownloads[item.id] = item;
        _controller.add(item); // Emit to stream
      }
      return;
    }

    // Scan and fix existing items (recursive search in subdirectories)
    final fixedItems = await _libraryScanner.scanAndFix(
      initialList,
      downloadPath,
    );
    for (final item in fixedItems) {
      _activeDownloads[item.id] = item;
      _controller.add(item); // Emit to stream
    }

    await _scanLibrary(downloadPath);
  }

  Future<String?> _getDownloadPath() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return null;
      return '$userProfile\\Videos\\VOILA';
    }
    return null;
  }

  Future<void> _scanLibrary(String downloadPath) async {
    try {
      final newItems = await _libraryScanner.scanForNewFiles(
        _activeDownloads.values.toList(),
        downloadPath,
      );

      for (final item in newItems) {
        _activeDownloads[item.id] = item;
        _controller.add(item);
      }

      if (newItems.isNotEmpty) {
        _saveToDisk();
      }
    } catch (e) {
      LoggerService.e('Library scan failed', e);
    }
  }

  @override
  Future<void> refreshLibrary() async {
    LoggerService.i('Refreshing library...');
    final downloadPath = await _getDownloadPath();
    if (downloadPath == null) return;

    // 1. Remove duplicate files from filesystem
    final duplicateDetector = DuplicateDetectorService();
    final dupResult = await duplicateDetector.findAndRemoveDuplicates(
      downloadPath,
    );

    if (dupResult.duplicatesRemoved > 0) {
      LoggerService.i(
        'Removed ${dupResult.duplicatesRemoved} duplicate files, '
        'recovered ${_formatBytes(dupResult.bytesRecovered)}',
      );
    }

    // 2. Remove entries from app state that reference deleted duplicates
    final removedPaths = dupResult.duplicateDetails
        .map((d) => d.removed)
        .toSet();
    final itemsToRemove = <String>[];

    for (final entry in _activeDownloads.entries) {
      final item = entry.value;
      if (item.filePath != null && removedPaths.contains(item.filePath)) {
        itemsToRemove.add(entry.key);
      }
    }

    for (final id in itemsToRemove) {
      _activeDownloads.remove(id);
      LoggerService.debug('Removed duplicate entry from app: $id');
    }

    // 3. Re-scan and fix existing items
    final currentItems = _activeDownloads.values.toList();
    final fixedItems = await _libraryScanner.scanAndFix(
      currentItems,
      downloadPath,
    );

    for (final item in fixedItems) {
      _activeDownloads[item.id] = item;
      _controller.add(item);
    }

    // 4. Scan for new files
    await _scanLibrary(downloadPath);
    _saveToDisk();

    LoggerService.i(
      'Library refresh complete. Duplicates removed: ${dupResult.duplicatesRemoved}',
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

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

    DownloadRequest effectiveRequest = request;
    if (request.url.contains('kick.com')) {
      effectiveRequest = request.copyWith(concurrentFragments: 64);
    }

    String initialTitle = _extractInitialTitle(effectiveRequest.url);
    int nextOrder = 0;
    if (_activeDownloads.isNotEmpty) {
      final maxOrder = _activeDownloads.values
          .map((e) => e.sortOrder)
          .reduce((a, b) => a > b ? a : b);
      nextOrder = maxOrder + 1;
    }

    final item = DownloadItem(
      id: id,
      request: effectiveRequest,
      title: initialTitle,
      sortOrder: nextOrder,
    );
    _update(item);

    _startDownloadProcess(id, effectiveRequest);
    return id;
  }

  Future<void> _startDownloadProcess(String id, DownloadRequest request) async {
    int retryCount = 0;
    const maxRetries = 3;

    Future<void> run() async {
      File? tempCookiesFile;
      try {
        // 1. Prepare Cookies
        DownloadRequest currentRequest = request;
        if (request.rawCookies != null && request.rawCookies!.isNotEmpty) {
          // Check if it's a Header string (Extension) or Netscape file content
          // Headers usually have "name=value;" and NO tabs. Netscape has tabs.
          final isHeader =
              !request.rawCookies!.contains('\t') &&
              request.rawCookies!.contains('=');

          if (!isHeader) {
            try {
              final tempDir = Directory.systemTemp;
              tempCookiesFile = File('${tempDir.path}/md_cookies_$id.txt');
              await tempCookiesFile.writeAsString(request.rawCookies!);
              currentRequest = request.copyWith(
                cookiesFilePath: tempCookiesFile.path,
              );
            } catch (e) {
              LoggerService.w('Failed to create temp cookies file: $e');
            }
          }
        }

        while (retryCount < maxRetries) {
          if (_activeDownloads[id]?.status == DownloadStatus.canceled ||
              _activeDownloads[id]?.status == DownloadStatus.paused) {
            return;
          }

          try {
            // 2. Pre-flight Check: Disk Space
            if (retryCount == 0) {
              await _checkDiskSpace();
            }

            // 3. Status Update
            if (retryCount > 0) {
              _update(
                _activeDownloads[id]!.copyWith(
                  status: DownloadStatus.extracting,
                  speed: 'Retry ${retryCount + 1}/$maxRetries...',
                ),
              );
              await Future.delayed(Duration(seconds: 5)); // Backoff
            } else {
              _update(
                _activeDownloads[id]!.copyWith(
                  status: DownloadStatus.extracting,
                ),
              );
            }

            // 4. Metadata Extraction (Retried if fails)
            String finalTitle = _activeDownloads[id]?.title ?? 'Video';
            String? finalThumbnail = _activeDownloads[id]?.thumbnailUrl;

            try {
              final metadata = await _source.fetchMetadata(
                currentRequest.url,
                cookies: currentRequest.rawCookies,
              );
              final String? fetchedTitle = metadata['title'];
              finalThumbnail = metadata['thumbnail'];

              // Platform-specific title logic...
              if (currentRequest.url.contains('twitter.com') ||
                  currentRequest.url.contains('x.com')) {
                final String? uploader =
                    metadata['uploader'] ?? metadata['uploader_id'];
                final String? tweetId = metadata['id'];
                if (fetchedTitle == null ||
                    fetchedTitle.isEmpty ||
                    fetchedTitle == tweetId ||
                    fetchedTitle.contains('twitter.com')) {
                  if (uploader != null && tweetId != null) {
                    finalTitle = '$uploader - $tweetId';
                  } else if (tweetId != null) {
                    finalTitle = 'Tweet $tweetId';
                  }
                } else {
                  finalTitle = fetchedTitle;
                }
              } else if (fetchedTitle != null &&
                  fetchedTitle.isNotEmpty &&
                  fetchedTitle != 'null' &&
                  fetchedTitle != metadata['id']) {
                finalTitle = fetchedTitle;
              }

              finalTitle = TitleCleanerService.clean(finalTitle);
              _update(
                _activeDownloads[id]!.copyWith(
                  title: finalTitle,
                  thumbnailUrl: finalThumbnail,
                ),
              );
              currentRequest = currentRequest.copyWith(
                customFilename: '$finalTitle.%(ext)s',
              );
            } catch (e) {
              LoggerService.w(
                'Metadata extraction failed (retry possible): $e',
              );
              // If metadata fails, we still try to download with derived title as fallback or retry
              if (retryCount < maxRetries - 1) {
                retryCount++;
                continue; // Retry whole loop
              }
              finalTitle = TitleCleanerService.deriveTitleFromUrl(
                currentRequest.url,
              );
            }

            // 5. Download Execution
            _update(
              _activeDownloads[id]!.copyWith(
                status: DownloadStatus.downloading,
              ),
            );

            await for (final progress in _source.download(id, currentRequest)) {
              if (progress.isDuplicate) {
                _update(
                  _activeDownloads[id]!.copyWith(
                    status: DownloadStatus.duplicate,
                    progress: 1.0,
                    speed: 'Doublon',
                    title: progress.title ?? _activeDownloads[id]!.title,
                    filePath:
                        progress.filePath ?? _activeDownloads[id]!.filePath,
                  ),
                );
                return;
              }

              _update(
                _activeDownloads[id]!.copyWith(
                  progress: progress.progress >= 0
                      ? progress.progress
                      : _activeDownloads[id]!.progress,
                  eta: progress.eta,
                  speed: progress.speed,
                  totalSize: progress.totalSize,
                  downloadedSize: progress.downloadedSize,
                  step: progress.step,
                  title: _shouldUpdateTitle(
                    _activeDownloads[id]!.title,
                    progress.title,
                  ),
                  filePath: progress.filePath ?? _activeDownloads[id]!.filePath,
                ),
              );
            }

            // 6. Success
            _update(
              _activeDownloads[id]!.copyWith(
                status: DownloadStatus.completed,
                progress: 1.0,
              ),
            );
            NotificationService().showDownloadComplete(
              _activeDownloads[id]!.title ?? 'Download Complete',
            );
            return;
          } catch (e) {
            // Rethrow if it's a fatal non-retryable error (like Disk Space)
            if (e.toString().contains('Low Disk Space')) rethrow;

            retryCount++;
            LoggerService.e('Download try $retryCount failed: $e');
            if (retryCount >= maxRetries) rethrow;
          }
        }
      } catch (e, st) {
        LoggerService.e('Download $id FATAL ERROR', e, st);
        if (GalleryDlSource.shouldUseFallback(request.url)) {
          try {
            await _tryGalleryDlFallback(id, request);
            return;
          } catch (ge) {
            LoggerService.w('Gallery DL fallback failed: $ge');
          }
        }
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.failed,
            error: e.toString(),
          ),
        );
        NotificationService().showDownloadFailed(
          _activeDownloads[id]?.title ?? 'Download Failed',
          e.toString(),
        );
      } finally {
        if (tempCookiesFile?.existsSync() ?? false) {
          tempCookiesFile?.deleteSync();
        }
      }
    }

    run();
  }

  Future<void> _tryGalleryDlFallback(String id, DownloadRequest request) async {
    _update(_activeDownloads[id]!.copyWith(status: DownloadStatus.downloading));
    await for (final progress in _galleryDlSource.download(id, request)) {
      if (progress.isComplete) {
        _update(
          _activeDownloads[id]!.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
            title: progress.title ?? _activeDownloads[id]?.title ?? 'Unknown',
          ),
        );
      } else {
        _update(
          _activeDownloads[id]!.copyWith(
            speed: progress.status,
            title:
                progress.title ??
                _activeDownloads[id]?.title ??
                'Processing...',
          ),
        );
      }
    }
  }

  @override
  Future<void> pauseDownload(String id) async {
    await _source.cancel(id);
    if (_activeDownloads.containsKey(id)) {
      _update(
        _activeDownloads[id]!.copyWith(
          status: DownloadStatus.paused,
          speed: 'Paused',
        ),
      );
    }
  }

  @override
  Future<void> cancelDownload(String id) async {
    await _source.cancel(id);
    if (_activeDownloads.containsKey(id)) {
      _update(
        _activeDownloads[id]!.copyWith(
          status: DownloadStatus.canceled,
          speed: 'Canceled',
        ),
      );
    }
  }

  @override
  Future<void> deleteDownload(String id) async {
    // 1. Cancel active process if running
    await _source.cancel(id);

    // 2. Locate the item to find its file path
    final item = _activeDownloads[id];
    if (item != null && item.filePath != null) {
      try {
        final file = File(item.filePath!);

        // Delete main file
        if (await file.exists()) {
          await file.delete();
          LoggerService.i('Deleted file: ${item.filePath}');
        }

        // Delete sidecar thumbnails (.jpg, .webp, .png next to video)
        final dotIndex = item.filePath!.lastIndexOf('.');
        if (dotIndex != -1) {
          final basePath = item.filePath!.substring(0, dotIndex);
          for (final ext in ['.jpg', '.webp', '.png']) {
            try {
              final thumbFile = File('$basePath$ext');
              if (await thumbFile.exists()) {
                await thumbFile.delete();
                LoggerService.i('Deleted thumbnail: $basePath$ext');
              }
            } catch (_) {}
          }
        }

        // 3. Cleanup temporary files (.part, .ytdl, etc.)
        final directory = file.parent;
        if (await directory.exists()) {
          final filename = file.uri.pathSegments.last.replaceAll(
            RegExp(r'\.\w+$'),
            '',
          );
          await for (final entity in directory.list()) {
            if (entity is File) {
              final name = entity.uri.pathSegments.last;
              if (name.contains(filename) &&
                  (name.endsWith('.part') ||
                      name.endsWith('.ytdl') ||
                      name.endsWith('.aria2') ||
                      name.contains('.f') ||
                      name.endsWith('.temp'))) {
                try {
                  await entity.delete();
                  LoggerService.debug('Cleaned up temp file: $name');
                } catch (_) {}
              }
            }
          }
        }
      } catch (e) {
        LoggerService.w('Failed to delete files for $id: $e');
      }
    }

    // 4. Remove from state and persistence
    _activeDownloads.remove(id);
    if (item != null) {
      _controller.add(item.copyWith(status: DownloadStatus.canceled));
      _saveToDisk();
    }

    LoggerService.i('Download removed: ${item?.title ?? id}');
  }

  @override
  Future<void> reorderDownloads(int oldIndex, int newIndex) async {
    final list = _activeDownloads.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (int i = 0; i < list.length; i++) {
      final updated = list[i].copyWith(sortOrder: i);
      _activeDownloads[updated.id] = updated;
      _controller.add(updated);
    }
    _saveToDisk();
  }

  @override
  Future<void> resumeDownload(String id) async {
    if (_activeDownloads.containsKey(id)) {
      _startDownloadProcess(id, _activeDownloads[id]!.request);
    }
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

  @override
  Future<Map<String, dynamic>> fetchMetadata(
    String url, {
    String? cookies,
  }) async {
    return _source.fetchMetadata(url, cookies: cookies);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlaylist(String url) async {
    return _source.fetchPlaylist(url);
  }

  String _extractInitialTitle(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube Video';
    }
    if (url.contains('twitter.com') || url.contains('x.com')) {
      return 'Twitter Video';
    }
    if (url.contains('twitch.tv')) {
      return 'Twitch Video';
    }
    if (url.contains('tiktok.com')) {
      return 'TikTok Video';
    }
    if (url.contains('kick.com')) {
      return 'Kick Video';
    }
    return 'Video';
  }

  String _shouldUpdateTitle(String? current, String? proposed) {
    if (proposed == null || proposed.isEmpty) return current ?? 'Video';
    if (current == null ||
        current.isEmpty ||
        current == 'Video' ||
        current.startsWith('Video ')) {
      return proposed;
    }
    // If the proposed title contains technical suffixes and current doesn't, keep current
    if (proposed.contains('.fhls') || proposed.contains('.f\\d+')) {
      if (!current.contains('.fhls') && !current.contains('.f\\d+')) {
        return current;
      }
    }
    return proposed;
  }

  Future<void> _checkDiskSpace() async {
    if (!Platform.isWindows) return;
    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:';
      final drive = userProfile.split(':')[0];
      final result = await Process.run('powershell', [
        '-Command',
        'Get-Volume -DriveLetter $drive | Select-Object -ExpandProperty SizeRemaining',
      ]);
      if (result.exitCode == 0) {
        final bytes = int.tryParse(result.stdout.toString().trim());
        if (bytes != null) {
          if (bytes < 2 * 1024 * 1024 * 1024) {
            throw Exception(
              'Low Disk Space: ${_formatBytes(bytes)} free. Min 2GB required.',
            );
          }
          LoggerService.i('Disk Space Check: ${_formatBytes(bytes)} free (OK)');
        }
      }
    } catch (e) {
      if (e.toString().contains('Low Disk Space')) rethrow;
    }
  }

  @override
  Future<void> clearHistory() async {
    // Remove all non-active downloads
    final keysToRemove = <String>[];
    _activeDownloads.forEach((key, value) {
      if (value.status == DownloadStatus.completed ||
          value.status == DownloadStatus.failed ||
          value.status == DownloadStatus.canceled) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _activeDownloads.remove(key);
    }

    // Refresh the stream with the new list (or just next save relies on UI poll? UI needs push)
    // We should probably emit the full list update or let the provider poll/refresh
    // Re-emitting current items one by one might be noisy, but provider listens to stream.
    // Provider implementation is "add/update if id matches, add if not". It doesn't handle removals via stream well except logic.
    // Ideally we should have a "Sync" event or just rely on provider refreshing list manually.
    // For now, let's just save. The provider calls getCurrentDownloads() normally.
    _saveToDisk();
  }

  @override
  Future<void> exportHistory(String path) async {
    final history = _activeDownloads.values.map((e) => e.toJson()).toList();
    final jsonStr = jsonEncode(history);
    final file = File(path);
    await file.writeAsString(jsonStr);
  }

  @override
  Future<void> importHistory(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final jsonStr = await file.readAsString();
    final List<dynamic> list = jsonDecode(jsonStr);

    bool changed = false;
    for (final map in list) {
      try {
        final item = DownloadItem.fromJson(map);
        if (!_activeDownloads.containsKey(item.id)) {
          _activeDownloads[item.id] = item;
          _controller.add(item);
          changed = true;
        }
      } catch (e) {
        LoggerService.w("Failed to import history item: $e");
      }
    }

    if (changed) {
      _saveToDisk();
    }
  }
}
