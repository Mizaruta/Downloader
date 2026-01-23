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
}
