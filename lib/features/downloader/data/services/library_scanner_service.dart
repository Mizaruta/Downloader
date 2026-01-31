import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:modern_downloader/core/logger/logger_service.dart';
import 'package:modern_downloader/features/downloader/domain/entities/download_item.dart';
import 'package:modern_downloader/features/downloader/domain/entities/download_request.dart';
import 'package:modern_downloader/features/downloader/domain/enums/download_status.dart';
import 'package:modern_downloader/core/services/title_cleaner_service.dart';
import 'package:modern_downloader/core/services/metadata_extractor_service.dart';
import 'package:modern_downloader/core/services/thumbnail_service.dart';
import 'package:modern_downloader/services/binary_locator.dart';

class LibraryScannerService {
  final BinaryLocator _binaryLocator;
  late final ThumbnailService _thumbnailService;

  /// Cache of all video files found during scanning
  List<File>? _videoFileCache;
  String? _lastScannedPath;

  LibraryScannerService(this._binaryLocator) {
    _thumbnailService = ThumbnailService(_binaryLocator);
  }

  /// Scans current items and fixes paths, thumbnails, and status
  Future<List<DownloadItem>> scanAndFix(
    List<DownloadItem> items,
    String basePath,
  ) async {
    final fixedItems = <DownloadItem>[];
    LoggerService.i('LibraryScanner: logic start for ${items.length} items');

    // Build cache of all video files in basePath (recursive)
    await _buildVideoCache(basePath);

    for (final item in items) {
      if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.extracting) {
        fixedItems.add(item);
        continue;
      }

      var fixedItem = item;

      // 1. Check Main File
      if (item.filePath == null || !File(item.filePath!).existsSync()) {
        final foundPath = _findFileFor(item);
        if (foundPath != null) {
          LoggerService.debug('LibraryScanner: Fixed path for ${item.title}');
          fixedItem = fixedItem.copyWith(filePath: foundPath);

          // File found - mark as completed if it was failed or paused
          if (fixedItem.status == DownloadStatus.failed ||
              fixedItem.status == DownloadStatus.paused) {
            fixedItem = fixedItem.copyWith(status: DownloadStatus.completed);
          }
        } else {
          if (fixedItem.status == DownloadStatus.completed) {
            LoggerService.w('LibraryScanner: File missing for ${item.title}');
            fixedItem = fixedItem.copyWith(
              status: DownloadStatus.failed,
              error: 'File missing from disk',
            );
          }
        }
      } else {
        // File path exists and file is present - ensure status is completed
        if (fixedItem.status == DownloadStatus.paused ||
            fixedItem.status == DownloadStatus.failed) {
          fixedItem = fixedItem.copyWith(status: DownloadStatus.completed);
        }
      }

      // 2. Check/Fix Thumbnail - validate existing and generate if missing
      if (fixedItem.filePath != null &&
          File(fixedItem.filePath!).existsSync()) {
        // First, validate existing thumbnailUrl - clear if file doesn't exist
        if (fixedItem.thumbnailUrl != null &&
            !fixedItem.thumbnailUrl!.startsWith('http')) {
          // It's a local path - check if file exists
          String decodedPath = fixedItem.thumbnailUrl!;
          try {
            decodedPath = Uri.decodeFull(fixedItem.thumbnailUrl!);
          } catch (_) {}

          if (!File(decodedPath).existsSync()) {
            // Thumbnail file is missing - clear it so we can regenerate
            fixedItem = fixedItem.copyWith(thumbnailUrl: null);
          }
        }

        // Now try to find or generate thumbnail if needed
        if (fixedItem.thumbnailUrl == null ||
            !fixedItem.thumbnailUrl!.startsWith('http')) {
          // First try existing sidecar
          var thumb = _findSidecarThumbnail(fixedItem.filePath!);

          // If no sidecar, generate one
          thumb ??= await _thumbnailService.generateThumbnail(
            fixedItem.filePath!,
          );

          if (thumb != null) {
            fixedItem = fixedItem.copyWith(thumbnailUrl: thumb);
          }
        }
      }

      // 3. Fix source if it's "Other" or "Local" and we have a file path
      if (fixedItem.filePath != null &&
          (fixedItem.source == 'Other' || fixedItem.source == 'Local')) {
        final detectedSource = _detectSource(
          null, // No URL to extract from for existing items
          fixedItem.filePath!,
          basePath,
        );

        // Create synthetic URL for proper source detection
        if (detectedSource != 'local') {
          final newUrl = 'https://$detectedSource.detected/imported';
          fixedItem = fixedItem.copyWith(request: DownloadRequest(url: newUrl));
        }
      }

      fixedItems.add(fixedItem);
    }
    return fixedItems;
  }

  /// Scans the download directory recursively for new files not in the list
  Future<List<DownloadItem>> scanForNewFiles(
    List<DownloadItem> knownItems,
    String downloadPath,
  ) async {
    final newItems = <DownloadItem>[];
    try {
      final dir = Directory(downloadPath);
      if (!dir.existsSync()) return [];

      final extractor = MetadataExtractorService(_binaryLocator);

      // Get all known paths (normalized) to avoid duplicates
      final knownPaths = knownItems
          .where((i) => i.filePath != null)
          .map((i) => i.filePath!.toLowerCase())
          .toSet();

      // Scan recursively
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          if (knownPaths.contains(entity.path.toLowerCase())) continue;
          if (_isVideo(entity.path)) {
            LoggerService.i('LibraryScanner: Found new video ${entity.path}');

            final id = const Uuid().v4();
            final metadata = await extractor.extract(entity.path);
            final filename = entity.uri.pathSegments.last;
            final cleanTitle = TitleCleanerService.clean(
              metadata?.title ?? filename,
            );

            // Detect source from metadata URL or folder structure
            final source = _detectSource(
              metadata?.sourceUrl,
              entity.path,
              downloadPath,
            );

            final newItem = DownloadItem(
              id: id,
              // Use a synthetic URL with the source domain for proper detection
              request: DownloadRequest(
                url: metadata?.sourceUrl ?? 'https://$source.detected/imported',
              ),
              title: cleanTitle,
              status: DownloadStatus.completed,
              progress: 1.0,
              filePath: entity.path,
              sortOrder: 9999,
              thumbnailUrl: _findSidecarThumbnail(entity.path),
            );
            newItems.add(newItem);
          }
        }
      }
    } catch (e) {
      LoggerService.e('LibraryScanner: Error scanning for new files', e);
    }
    return newItems;
  }

  /// Detects the source of a video from metadata URL or folder structure
  String _detectSource(String? sourceUrl, String filePath, String basePath) {
    // 1. Try to extract from source URL (most accurate)
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(sourceUrl);
        final host = uri.host.toLowerCase();
        if (host.contains('youtube') || host.contains('youtu.be')) {
          return 'youtube';
        }
        if (host.contains('twitter') || host == 'x.com') return 'twitter';
        if (host.contains('instagram')) return 'instagram';
        if (host.contains('tiktok')) return 'tiktok';
        if (host.contains('twitch')) return 'twitch';
        if (host.contains('kick')) return 'kick';
        if (host.contains('reddit') || host.contains('redd.it')) {
          return 'reddit';
        }
        if (host.contains('pornhub')) return 'pornhub';
        if (host.contains('xvideos')) return 'xvideos';
        if (host.contains('xhamster')) return 'xhamster';
        if (host.contains('xnxx')) return 'xnxx';
      } catch (_) {}
    }

    // 3. Try to extract from parent folder name
    final relativePath = filePath
        .replaceFirst(basePath, '')
        .replaceAll('\\', '/');
    final parts = relativePath.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.length > 1) {
      // First part of relative path is the subfolder (e.g., "Twitter", "YouTube")
      final folder = parts.first.toLowerCase();
      if (_isKnownSource(folder)) {
        return folder;
      }
    }

    return 'local';
  }

  /// Checks if a folder name matches a known source
  bool _isKnownSource(String folder) {
    const knownSources = [
      'twitter',
      'youtube',
      'instagram',
      'tiktok',
      'twitch',
      'kick',
      'reddit',
      'facebook',
      'xnxx',
      'xhamster',
      'pornhub',
      'xvideos',
      'vimeo',
      'dailymotion',
      'soundcloud',
    ];
    return knownSources.contains(folder);
  }

  /// Builds a cache of all video files in the given path (recursive)
  Future<void> _buildVideoCache(String basePath) async {
    if (_lastScannedPath == basePath && _videoFileCache != null) {
      return; // Use existing cache
    }

    _videoFileCache = [];
    _lastScannedPath = basePath;

    try {
      final dir = Directory(basePath);
      if (!dir.existsSync()) return;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && _isVideo(entity.path)) {
          _videoFileCache!.add(entity);
        }
      }
      LoggerService.i(
        'LibraryScanner: Cached ${_videoFileCache!.length} video files from $basePath',
      );
    } catch (e) {
      LoggerService.e('LibraryScanner: Error building cache', e);
    }
  }

  /// Finds a file matching the item's title using normalized comparison
  String? _findFileFor(DownloadItem item) {
    if (item.title == null || _videoFileCache == null) return null;

    final normalizedTitle = _normalize(item.title!);
    if (normalizedTitle.isEmpty) return null;

    // Try exact filename match from previous path
    if (item.filePath != null) {
      final oldFilename = item.filePath!.split(RegExp(r'[/\\]')).last;
      final normalizedOldFilename = _normalize(oldFilename);

      for (final file in _videoFileCache!) {
        final filename = file.uri.pathSegments.last;
        final normalizedFilename = _normalize(filename);

        if (normalizedFilename == normalizedOldFilename) {
          return file.path;
        }
      }
    }

    // Try title-based matching
    for (final file in _videoFileCache!) {
      final filename = file.uri.pathSegments.last;
      final normalizedFilename = _normalize(filename);

      // Check if title is substantially contained in filename or vice versa
      if (_fuzzyMatch(normalizedTitle, normalizedFilename)) {
        return file.path;
      }
    }

    return null;
  }

  /// Normalizes a string for comparison (removes special chars, lowercase)
  String _normalize(String input) {
    // Remove file extensions
    var s = input.replaceAll(
      RegExp(r'\.(mp4|mkv|webm|mov|avi)$', caseSensitive: false),
      '',
    );
    // Remove URLs
    s = s.replaceAll(RegExp(r'https?[^\s]*'), '');
    // Remove special chars, keep only alphanumeric and spaces
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return s;
  }

  /// Fuzzy matching - checks if significant words overlap
  bool _fuzzyMatch(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;

    // Split into words
    final wordsA = a.split(' ').where((w) => w.length > 2).toSet();
    final wordsB = b.split(' ').where((w) => w.length > 2).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    // Count matching words
    final matches = wordsA.intersection(wordsB).length;
    final minWords = wordsA.length < wordsB.length
        ? wordsA.length
        : wordsB.length;

    // Require at least 50% word overlap
    return matches >= (minWords * 0.5).ceil() && matches >= 1;
  }

  String? _findSidecarThumbnail(String videoPath) {
    try {
      final dotIndex = videoPath.lastIndexOf('.');
      if (dotIndex == -1) return null;
      final basePath = videoPath.substring(0, dotIndex);

      final exts = ['.jpg', '.webp', '.png'];
      for (final ext in exts) {
        final path = '$basePath$ext';
        if (File(path).existsSync()) return path;
      }
    } catch (_) {}
    return null;
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi');
  }
}
