import 'package:modern_downloader/core/logger/logger_service.dart';

class TitleCleanerService {
  static final RegExp _spamPatterns = RegExp(
    r'(\(Official Video\)|\[Official Video\]|\(Lyrics\)|\(Audio\)|\[4K\]|\[HD\]|\(feat\..*?\)|\(ft\..*?\))',
    caseSensitive: false,
  );

  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );

  static String clean(String title) {
    String cleaned = title;

    // Remove Emoji
    cleaned = cleaned.replaceAll(_emojiPattern, '');

    // Remove Spam patterns
    cleaned = cleaned.replaceAll(_spamPatterns, '');

    // Remove pipes and other separators often used in YouTube titles
    cleaned = cleaned.replaceAll('|', '-');

    // Remove strictly restricted Windows characters: < > : " / \ | ? *
    cleaned = cleaned.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');

    // Remove technical suffixes (yt-dlp fragments)
    cleaned = cleaned.replaceAll(RegExp(r'\.fhls-\d+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\.f\d+'), '');
    cleaned = cleaned.replaceAll('.part', '');
    cleaned = cleaned.replaceAll('.ytdl', '');

    // Collapse multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Trim
    cleaned = cleaned.trim();

    // Truncate to avoid path length issues in Windows (260 char limit total, let's keep filename < 200)
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 197)}...';
    }

    if (cleaned != title) {
      LoggerService.debug('Title cleaned: "$title" -> "$cleaned"');
    }

    return cleaned;
  }

  static String deriveTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Strategy 1: Last path segment
      if (uri.pathSegments.isNotEmpty) {
        String lastSegment = uri.pathSegments.last;

        // Remove file extension if present
        if (lastSegment.contains('.')) {
          lastSegment = lastSegment.split('.').first;
        }

        // Replace hyphens/underscores with spaces
        lastSegment = lastSegment.replaceAll(RegExp(r'[-_]'), ' ');

        // If segment looks like an ID (alphanumeric, no spaces, > 8 chars), usually not a good title
        // But if it has spaces now, it might be okay.

        // Filter out obviously bad titles (just numbers)
        if (RegExp(r'^\d+$').hasMatch(lastSegment)) {
          // If it's x.com or twitter.com, try to get the uploader/handle from the URL
          if (url.contains('x.com') || url.contains('twitter.com')) {
            String? handle;
            if (uri.pathSegments.length >= 2) {
              handle = uri.pathSegments[0];
            }
            if (handle != null && handle != 'status' && handle != 'i') {
              return '$handle - $lastSegment';
            }
            return 'Tweet $lastSegment';
          }
          return 'Video $lastSegment';
        }

        return clean(lastSegment);
      }
    } catch (e) {
      // ignore
    }
    return 'Video_${DateTime.now().millisecondsSinceEpoch}';
  }
}
