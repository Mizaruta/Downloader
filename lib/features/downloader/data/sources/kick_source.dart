import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/logger/logger_service.dart';

class KickSource {
  /// Fetches stream URL and thumbnail URL from Kick.com
  /// Returns a Map with 'streamUrl' and 'thumbnailUrl'
  Future<Map<String, String?>> fetchKickDetails(String url) async {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isEmpty) return {};

      String channel = segments.first;
      // Handle kick.com/channel/video/id format if needed, but usually channel is first

      LoggerService.debug('KickSource: Fetching details for channel: $channel');

      // Unofficial Kick API endpoint
      final apiUrl = 'https://kick.com/api/v1/channels/$channel';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playbackUrl = data['playback_url'] as String?;

        String? thumbnailUrl;
        if (data['user'] != null) {
          thumbnailUrl = data['user']['profile_pic'] as String?;
        }

        return {
          if (playbackUrl != null) 'streamUrl': playbackUrl,
          if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        };
      } else {
        LoggerService.w('Kick API returned status: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.e('KickSource: Failed to fetch details', e);
    }
    return {};
  }
}
