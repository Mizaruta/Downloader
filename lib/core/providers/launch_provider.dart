import 'package:flutter_riverpod/flutter_riverpod.dart';

class LaunchData {
  final String url;
  final String? cookies;
  final String? userAgent;
  final bool isAudioOnly;
  final bool shouldAutoStart;
  final bool isPlaylist;

  LaunchData({
    required this.url,
    this.cookies,
    this.userAgent,
    this.isAudioOnly = false,
    this.shouldAutoStart = false,
    this.isPlaylist = false,
  });
}

/// Holds the data that triggered the app launch or a remote request.
final launchDataProvider = StateProvider<LaunchData?>((ref) => null);

// Keep this for backward compatibility if needed, or deprecate
final launchUrlProvider = StateProvider<String?>((ref) => null);
