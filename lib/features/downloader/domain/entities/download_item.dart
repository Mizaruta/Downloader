import '../enums/download_status.dart';
import 'download_request.dart';

class DownloadItem {
  final String id;
  final DownloadRequest request;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String eta;
  final String speed;
  final String? title;
  final String? error;

  const DownloadItem({
    required this.id,
    required this.request,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.eta = '',
    this.speed = '',
    this.title,
    this.error,
  });

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? eta,
    String? speed,
    String? title,
    String? error,
  }) {
    return DownloadItem(
      id: id,
      request: request,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      eta: eta ?? this.eta,
      speed: speed ?? this.speed,
      title: title ?? this.title,
      error: error ?? this.error,
    );
  }
}
