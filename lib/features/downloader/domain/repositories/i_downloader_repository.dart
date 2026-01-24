import '../entities/download_item.dart';
import '../entities/download_request.dart';

abstract class IDownloaderRepository {
  Future<String> startDownload(DownloadRequest request);
  Future<void> cancelDownload(String id);
  Future<void> pauseDownload(String id);
  Future<void> resumeDownload(String id);
  Future<void> deleteDownload(String id);
  Future<void> reorderDownloads(int oldIndex, int newIndex);
  List<DownloadItem> getCurrentDownloads();
  Stream<DownloadItem> get downloadUpdateStream;
}
