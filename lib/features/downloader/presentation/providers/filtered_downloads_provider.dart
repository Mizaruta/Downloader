import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modern_downloader/features/downloader/domain/entities/download_item.dart';
import 'package:modern_downloader/features/downloader/domain/enums/download_status.dart';
import 'package:modern_downloader/features/downloader/presentation/providers/downloader_provider.dart';

// --- Filter State Definitions ---

enum DownloadStatusFilter {
  all,
  active, // Downloading, Extracting, Queued, Processing
  completed,
  failed, // Failed, Canceled
}

// Changed to String for dynamic source support
final downloadSourceFilterProvider = StateProvider<String?>(
  (ref) => null,
); // null = all

// --- Providers ---

final downloadSearchQueryProvider = StateProvider<String>((ref) => '');

final downloadStatusFilterProvider = StateProvider<DownloadStatusFilter>(
  (ref) => DownloadStatusFilter.all,
);

final selectedDownloadIdProvider = StateProvider<String?>((ref) => null);

// --- Logic ---

final filteredDownloadsProvider = Provider<AsyncValue<List<DownloadItem>>>((
  ref,
) {
  final allDownloadsState = ref.watch(downloadListProvider);
  final query = ref.watch(downloadSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(downloadStatusFilterProvider);
  final sourceFilter = ref.watch(downloadSourceFilterProvider);

  return allDownloadsState.when(
    data: (allDownloads) {
      final filtered = allDownloads.where((item) {
        // 1. Search Query
        if (query.isNotEmpty) {
          final title = (item.title ?? '').toLowerCase();
          final url = item.request.url.toLowerCase();
          if (!title.contains(query) && !url.contains(query)) {
            return false;
          }
        }

        // 2. Status Filter
        if (statusFilter != DownloadStatusFilter.all) {
          switch (statusFilter) {
            case DownloadStatusFilter.active:
              if (![
                DownloadStatus.downloading,
                DownloadStatus.extracting,
                DownloadStatus.queued,
                DownloadStatus.processing,
              ].contains(item.status)) {
                return false;
              }
              break;
            case DownloadStatusFilter.completed:
              if (item.status != DownloadStatus.completed) {
                return false;
              }
              break;
            case DownloadStatusFilter.failed:
              if (![
                DownloadStatus.failed,
                DownloadStatus.canceled,
              ].contains(item.status)) {
                return false;
              }
              break;
            case DownloadStatusFilter.all:
              break;
          }
        }

        // 3. Source Filter
        if (sourceFilter != null) {
          if (item.source != sourceFilter) {
            return false;
          }
        }

        return true;
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
