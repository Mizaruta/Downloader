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
  final String downloadedSize; // e.g., "10.5MiB"
  final String totalSize; // e.g., "300MiB"
  final int sortOrder;

  const DownloadItem({
    required this.id,
    required this.request,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.eta = '',
    this.speed = '',
    this.title,
    this.error,
    this.downloadedSize = '',
    this.totalSize = '',
    this.step = '',
    this.filePath,
    this.sortOrder = 0,
  });

  final String step; // Current step (e.g., "Merging audio/video...")

  final String? filePath;

  String get source {
    final url = request.url.toLowerCase();
    if (url.contains('youtube') || url.contains('youtu.be')) return 'YouTube';
    if (url.contains('instagram')) return 'Instagram';
    if (url.contains('twitter') || url.contains('x.com')) return 'Twitter';
    if (url.contains('twitch')) return 'Twitch';
    if (url.contains('kick')) return 'Kick';

    // Fallback: extract domain name (e.g., "dailymotion" from "dailymotion.com")
    try {
      final uri = Uri.parse(request.url);
      if (uri.host.isNotEmpty) {
        final host = uri.host.replaceFirst('www.', '');
        final parts = host.split('.');
        if (parts.length >= 2) {
          // Capitalize first letter
          final name = parts[0];
          return name[0].toUpperCase() + name.substring(1);
        }
        return host;
      }
    } catch (_) {}

    return 'Other';
  }

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? eta,
    String? speed,
    String? title,
    String? error,
    String? downloadedSize,
    String? totalSize,
    String? step,
    String? filePath,
    int? sortOrder,
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
      downloadedSize: downloadedSize ?? this.downloadedSize,
      totalSize: totalSize ?? this.totalSize,
      step: step ?? this.step,
      filePath: filePath ?? this.filePath,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request': request.toJson(),
      'status': status.index,
      'progress': progress,
      'eta': eta,
      'speed': speed,
      'title': title,
      'error': error,
      'downloadedSize': downloadedSize,
      'totalSize': totalSize,
      'step': step,
      'filePath': filePath,
      'sortOrder': sortOrder,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      request: DownloadRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      eta: json['eta'] as String? ?? '',
      speed: json['speed'] as String? ?? '',
      title: json['title'] as String?,
      error: json['error'] as String?,
      downloadedSize: json['downloadedSize'] as String? ?? '',
      totalSize: json['totalSize'] as String? ?? '',
      step: json['step'] as String? ?? '',
      filePath: json['filePath'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
