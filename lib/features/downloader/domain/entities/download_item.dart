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
  final bool usesAria2c;
  final String? thumbnailUrl; // Added field

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
    this.usesAria2c = false,
    this.thumbnailUrl,
  });

  final String step; // Current step (e.g., "Merging audio/video...")

  final String? filePath;

  String get source {
    try {
      final uri = Uri.parse(request.url);
      String textToCheck = uri.host.toLowerCase();

      if (uri.scheme == 'imported') {
        // Check the path (filename) for keywords since we don't have a domain
        textToCheck = uri.path.toLowerCase();
      }

      if (textToCheck.contains('youtube') || textToCheck.contains('youtu.be')) {
        return 'YouTube';
      }
      if (textToCheck.contains('instagram')) {
        return 'Instagram';
      }

      // Twitter/X logic
      if (textToCheck.contains('twitter') ||
          textToCheck == 'x.com' ||
          textToCheck.endsWith('.x.com')) {
        return 'Twitter';
      }

      if (textToCheck.contains('twitch')) {
        return 'Twitch';
      }
      if (textToCheck.contains('kick') &&
          !textToCheck.contains('kickstarter')) {
        return 'Kick';
      }
      if (textToCheck.contains('tiktok')) {
        return 'TikTok';
      }
      if (textToCheck.contains('reddit') || textToCheck.contains('redd.it')) {
        return 'Reddit';
      }
      if (textToCheck.contains('facebook') ||
          textToCheck.contains('fb.com') ||
          textToCheck.contains('fb.watch')) {
        return 'Facebook';
      }

      if (textToCheck.contains('xnxx')) {
        return 'Xnxx';
      }
      if (textToCheck.contains('xhamster')) {
        return 'Xhamster';
      }

      if (uri.scheme == 'imported') {
        return 'Local';
      }

      // Fallback: extract domain name
      if (textToCheck.isNotEmpty) {
        var name = textToCheck.replaceFirst('www.', '');
        final parts = name.split('.');
        if (parts.length > 2) {
          name = parts[parts.length - 2];
        } else if (parts.length == 2) {
          name = parts[0];
        }

        if (name.isNotEmpty) {
          return name[0].toUpperCase() + name.substring(1);
        }
        return name;
      }
    } catch (_) {}

    return 'Other';
  }

  DownloadItem copyWith({
    DownloadRequest? request,
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
    bool? usesAria2c,
    String? thumbnailUrl, // Added param
  }) {
    return DownloadItem(
      id: id,
      request: request ?? this.request,
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
      usesAria2c: usesAria2c ?? this.usesAria2c,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl, // Added assignment
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
      'usesAria2c': usesAria2c,
      'thumbnailUrl': thumbnailUrl, // Added
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
      usesAria2c: json['usesAria2c'] as bool? ?? false,
      thumbnailUrl: json['thumbnailUrl'] as String?, // Added
    );
  }
}
