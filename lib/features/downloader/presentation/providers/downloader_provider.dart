import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/enums/download_status.dart';
import '../../domain/repositories/i_downloader_repository.dart';
import '../../data/sources/yt_dlp_source.dart';
import '../../data/sources/gallery_dl_source.dart';
import '../../data/datasources/persistence_service.dart';
import '../../data/services/library_scanner_service.dart';
import '../../data/repositories/downloader_repository_impl.dart';
import 'package:modern_downloader/services/service_providers.dart';

// Data Layer Providers
final ytDlpSourceProvider = Provider<YtDlpSource>((ref) {
  return YtDlpSource(
    ref.read(binaryLocatorProvider),
    ref.read(processRunnerProvider),
  );
});

final galleryDlSourceProvider = Provider<GalleryDlSource>((ref) {
  return GalleryDlSource(ref.read(binaryLocatorProvider));
});

// Added persistenceServiceProvider
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService(ref.read(binaryLocatorProvider));
});

final downloaderRepositoryProvider = Provider<IDownloaderRepository>((ref) {
  return DownloaderRepositoryImpl(
    ref.read(ytDlpSourceProvider),
    ref.read(galleryDlSourceProvider),
    ref.read(persistenceServiceProvider),
    ref.read(libraryScannerServiceProvider),
  );
});

// Presentation Layer - Controller
final activeDownloadsProvider = StreamProvider<DownloadItem>((ref) {
  final repo = ref.watch(downloaderRepositoryProvider);
  return repo.downloadUpdateStream;
});

// Notifier to hold the list state
class DownloadListNotifier
    extends StateNotifier<AsyncValue<List<DownloadItem>>> {
  final IDownloaderRepository _repository;
  final Ref _ref;

  final List<DownloadRequest> _queue = [];

  DownloadListNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Simulate loading for better UX (Skeleton demonstration) or valid async load
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      final items = _repository.getCurrentDownloads();
      state = AsyncValue.data(items);
      _listenToUpdates();

      // Listen to Max Concurrent changes to auto-start pending downloads
      _ref.listen<AppSettings>(settingsProvider, (previous, next) {
        if (previous?.maxConcurrent != next.maxConcurrent) {
          _processQueue();
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _listenToUpdates() {
    _repository.downloadUpdateStream.listen((item) {
      if (!mounted) return;

      state.whenData((currentList) {
        bool found = false;
        final newState = currentList.map((e) {
          if (e.id == item.id) {
            found = true;
            return item;
          }
          return e;
        }).toList();

        if (!found) {
          newState.add(item);
        }

        state = AsyncValue.data(newState);

        if (item.status == DownloadStatus.completed ||
            item.status == DownloadStatus.failed ||
            item.status == DownloadStatus.canceled ||
            item.status == DownloadStatus.duplicate) {
          _processQueue();
        }

        // Auto-delete duplicates after 5 seconds
        if (item.status == DownloadStatus.duplicate) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              deleteDownload(item.id);
            }
          });
        }
      });
    });
  }

  void refreshList() {
    try {
      final items = _repository.getCurrentDownloads();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshLibrary() async {
    await _repository.refreshLibrary();
    refreshList();
  }

  Future<void> startDownload(
    String url, {
    String? rawCookies,
    String? videoFormatId,
    String? userAgent,
    String? cookiesFilePath,
    bool? organizeBySite,
    String? cookieBrowser,
  }) async {
    final settings = _ref.read(settingsProvider);

    final request = DownloadRequest(
      url: url,
      outputFolder: settings.outputFolder.isNotEmpty
          ? settings.outputFolder
          : null,
      audioOnly: settings.audioOnly,
      preferredQuality: settings.preferredQuality,
      outputFormat: settings.outputFormat,
      audioFormat: settings.audioFormat,
      embedThumbnail: settings.embedThumbnail,
      embedSubtitles: settings.embedSubtitles,
      twitterIncludeReplies: settings.twitterIncludeReplies,
      twitchDownloadChat: settings.twitchDownloadChat,
      twitchQuality: settings.twitchQuality,
      cookiesFilePath:
          cookiesFilePath ??
          (settings.cookiesFilePath.isNotEmpty
              ? settings.cookiesFilePath
              : null),
      useTorProxy: settings.useTorProxy,
      concurrentFragments: settings.concurrentFragments,
      rawCookies: rawCookies,
      videoFormatId: videoFormatId,
      cookieBrowser: cookieBrowser ?? settings.cookieBrowser,
      organizeBySite: organizeBySite ?? settings.organizeBySite,
      userAgent: userAgent,
    );

    _queue.add(request);
    await _processQueue();
  }

  Future<void> deleteDownload(String id) async {
    await _repository.deleteDownload(id);
    state.whenData((currentList) {
      final newState = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(newState);
    });
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    state.whenData((currentList) async {
      final items = List<DownloadItem>.from(currentList);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      state = AsyncValue.data(items);

      await _repository.reorderDownloads(oldIndex, newIndex);
    });
  }

  Future<void> cancelDownload(String id) async {
    await _repository.cancelDownload(id);
  }

  Future<void> retryDownload(DownloadItem item) async {
    await deleteDownload(item.id);
    _queue.add(item.request);
    await _processQueue();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    refreshList();
  }

  Future<void> exportHistory(String path) async {
    await _repository.exportHistory(path);
  }

  Future<void> importHistory(String path) async {
    await _repository.importHistory(path);
    refreshList();
  }

  Future<void> _processQueue() async {
    final currentList = state.valueOrNull ?? [];
    final activeCount = currentList
        .where(
          (i) =>
              i.status == DownloadStatus.downloading ||
              i.status == DownloadStatus.extracting,
        )
        .length;

    final settings = _ref.read(settingsProvider);
    final maxConcurrent = settings.maxConcurrent;

    if (activeCount < maxConcurrent && _queue.isNotEmpty) {
      final nextRequest = _queue.removeAt(0);
      await _repository.startDownload(nextRequest);
      _processQueue();
    }
  }
}

final downloadListProvider =
    StateNotifierProvider<DownloadListNotifier, AsyncValue<List<DownloadItem>>>(
      (ref) {
        return DownloadListNotifier(
          ref.read(downloaderRepositoryProvider),
          ref,
        );
      },
    );
