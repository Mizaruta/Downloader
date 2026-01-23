import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/enums/download_status.dart';
import '../../domain/repositories/i_downloader_repository.dart';
import '../../data/sources/yt_dlp_source.dart';
import '../../data/repositories/downloader_repository_impl.dart';
import '../../../../../services/service_providers.dart';

// Data Layer Providers
final ytDlpSourceProvider = Provider<YtDlpSource>((ref) {
  return YtDlpSource(
    ref.read(binaryLocatorProvider),
    ref.read(processRunnerProvider),
  );
});

final downloaderRepositoryProvider = Provider<IDownloaderRepository>((ref) {
  return DownloaderRepositoryImpl(ref.read(ytDlpSourceProvider));
});

// Presentation Layer - Controller
final activeDownloadsProvider = StreamProvider<DownloadItem>((ref) {
  final repo = ref.watch(downloaderRepositoryProvider);
  return repo.downloadUpdateStream;
});

// Notifier to hold the list state
class DownloadListNotifier extends StateNotifier<List<DownloadItem>> {
  final IDownloaderRepository _repository;
  final Ref _ref;

  static const int _maxConcurrentDownloads = 3;
  final List<DownloadRequest> _queue = [];

  DownloadListNotifier(this._repository, this._ref) : super([]) {
    _repository.downloadUpdateStream.listen((item) {
      if (!mounted) return;

      final oldState = state;
      state = [
        for (final exist in oldState)
          if (exist.id == item.id) item else exist,
      ];
      if (!oldState.any((e) => e.id == item.id)) {
        state = [...oldState, item];
      }

      if (item.status == DownloadStatus.completed ||
          item.status == DownloadStatus.failed ||
          item.status == DownloadStatus.canceled) {
        _processQueue();
      }
    });
  }

  Future<void> startDownload(String url) async {
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
      cookiesFilePath: settings.cookiesFilePath.isNotEmpty
          ? settings.cookiesFilePath
          : null,
      useTorProxy: settings.useTorProxy,
    );

    _queue.add(request);
    await _processQueue();
  }

  Future<void> _processQueue() async {
    final activeCount = state
        .where(
          (i) =>
              i.status == DownloadStatus.downloading ||
              i.status == DownloadStatus.extracting,
        )
        .length;

    if (activeCount < _maxConcurrentDownloads && _queue.isNotEmpty) {
      final nextRequest = _queue.removeAt(0);
      await _repository.startDownload(nextRequest);
      _processQueue();
    }
  }
}

final downloadListProvider =
    StateNotifierProvider<DownloadListNotifier, List<DownloadItem>>((ref) {
      return DownloadListNotifier(ref.read(downloaderRepositoryProvider), ref);
    });
