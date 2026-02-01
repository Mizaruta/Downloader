class GrabbedVideo {
  final String id;
  final String title;
  final String url;
  final String? originalUrl;
  final double duration;
  final String thumbnail;
  final String? uploader;
  final int? fileSize;
  bool isSelected;

  GrabbedVideo({
    required this.id,
    required this.title,
    required this.url,
    this.originalUrl,
    required this.duration,
    required this.thumbnail,
    this.uploader,
    this.fileSize,
    this.isSelected = true,
  });

  factory GrabbedVideo.fromJson(Map<String, dynamic> json) {
    String id = json['id']?.toString() ?? '';
    String title = json['title']?.toString() ?? 'Unknown Title';
    final String url = json['url']?.toString() ?? '';
    final String? originalUrl = json['original_url']?.toString();
    final double duration = (json['duration'] as num?)?.toDouble() ?? 0.0;
    final int? fileSize =
        json['filesize'] as int? ?? json['filesize_approx'] as int?;

    // Fallback for Rumble and others where flat-playlist is too minimal
    if (id.isEmpty || title == 'Unknown Title') {
      try {
        final uri = Uri.parse(url);
        if (uri.host.contains('rumble.com')) {
          // Rumble pattern: /v12345-title-slug.html
          String path = uri.path;
          if (path.startsWith('/')) path = path.substring(1);
          if (path.endsWith('.html')) path = path.substring(0, path.length - 5);

          final dashIndex = path.indexOf('-');
          if (dashIndex != -1) {
            if (id.isEmpty) id = path.substring(0, dashIndex);
            if (title == 'Unknown Title') {
              final slug = path.substring(dashIndex + 1);
              title = slug
                  .split('-')
                  .map((word) {
                    if (word.isEmpty) return '';
                    return word[0].toUpperCase() + word.substring(1);
                  })
                  .join(' ');
            }
          } else {
            if (id.isEmpty) id = path;
          }
        } else if (id.isEmpty && uri.pathSegments.isNotEmpty) {
          id = uri.pathSegments.last;
        }
      } catch (_) {}
    }

    return GrabbedVideo(
      id: id,
      title: title,
      url: url,
      originalUrl: originalUrl,
      duration: duration,
      thumbnail: _extractThumbnail(json),
      uploader: json['uploader']?.toString(),
      fileSize: fileSize,
    );
  }

  static String _extractThumbnail(Map<String, dynamic> json) {
    if (json['thumbnail'] != null) return json['thumbnail'].toString();

    if (json['thumbnails'] is List && (json['thumbnails'] as List).isNotEmpty) {
      // Sort by width if possible, or just take the last one
      final thumbnails = json['thumbnails'] as List;
      return thumbnails.last['url']?.toString() ?? '';
    }

    return '';
  }
}
