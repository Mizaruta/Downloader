class DownloadRequest {
  final String url;
  final String? outputFolder;
  final bool audioOnly;
  final String? customFilename;

  // Format settings
  final String preferredQuality;
  final String outputFormat; // mp4, mkv, webm
  final String audioFormat; // mp3, aac, opus
  final bool embedThumbnail;
  final bool embedSubtitles;

  // Platform-specific
  final bool twitterIncludeReplies;
  final bool twitchDownloadChat;
  final String twitchQuality;

  // Cookies for protected sites
  final String? cookiesFilePath;

  // Proxy settings
  final bool useTorProxy;

  const DownloadRequest({
    required this.url,
    this.outputFolder,
    this.audioOnly = false,
    this.customFilename,
    this.preferredQuality = 'best',
    this.outputFormat = 'mp4',
    this.audioFormat = 'mp3',
    this.embedThumbnail = true,
    this.embedSubtitles = false,
    this.twitterIncludeReplies = false,
    this.twitchDownloadChat = false,
    this.twitchQuality = '1080p60',
    this.cookiesFilePath,
    this.useTorProxy = false,
  });
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'outputFolder': outputFolder,
      'audioOnly': audioOnly,
      'customFilename': customFilename,
      'preferredQuality': preferredQuality,
      'outputFormat': outputFormat,
      'audioFormat': audioFormat,
      'embedThumbnail': embedThumbnail,
      'embedSubtitles': embedSubtitles,
      'twitterIncludeReplies': twitterIncludeReplies,
      'twitchDownloadChat': twitchDownloadChat,
      'twitchQuality': twitchQuality,
      'cookiesFilePath': cookiesFilePath,
      'useTorProxy': useTorProxy,
    };
  }

  factory DownloadRequest.fromJson(Map<String, dynamic> json) {
    return DownloadRequest(
      url: json['url'] as String,
      outputFolder: json['outputFolder'] as String?,
      audioOnly: json['audioOnly'] as bool? ?? false,
      customFilename: json['customFilename'] as String?,
      preferredQuality: json['preferredQuality'] as String? ?? 'best',
      outputFormat: json['outputFormat'] as String? ?? 'mp4',
      audioFormat: json['audioFormat'] as String? ?? 'mp3',
      embedThumbnail: json['embedThumbnail'] as bool? ?? true,
      embedSubtitles: json['embedSubtitles'] as bool? ?? false,
      twitterIncludeReplies: json['twitterIncludeReplies'] as bool? ?? false,
      twitchDownloadChat: json['twitchDownloadChat'] as bool? ?? false,
      twitchQuality: json['twitchQuality'] as String? ?? '1080p60',
      cookiesFilePath: json['cookiesFilePath'] as String?,
      useTorProxy: json['useTorProxy'] as bool? ?? false,
    );
  }
}
