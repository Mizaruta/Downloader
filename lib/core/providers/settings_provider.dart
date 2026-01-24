import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Settings State
class AppSettings {
  final bool audioOnly;
  final bool autoStart;
  final int maxConcurrent;
  final String outputFolder;
  final String preferredQuality;
  final String outputFormat; // mp4, mkv, webm
  final String audioFormat; // mp3, aac, opus
  final bool embedThumbnail;
  final bool embedSubtitles;

  // Site-specific settings
  final bool twitterIncludeReplies;
  final bool twitchDownloadChat;
  final String twitchQuality;
  final bool adultSitesEnabled;
  final String cookiesFilePath; // Path to cookies.txt for protected sites
  final bool useTorProxy; // Use Tor SOCKS5 proxy (127.0.0.1:9050)

  final String themeMode; // 'system', 'light', 'dark'

  const AppSettings({
    this.themeMode = 'system',
    this.audioOnly = false,
    this.autoStart = true,
    this.maxConcurrent = 3,
    this.outputFolder = '',
    this.preferredQuality = 'best',
    this.outputFormat = 'mp4', // Default to MP4 for max compatibility
    this.audioFormat = 'mp3',
    this.embedThumbnail = true,
    this.embedSubtitles = false,
    this.twitterIncludeReplies = false,
    this.twitchDownloadChat = false,
    this.twitchQuality = '1080p60',
    this.adultSitesEnabled = false,
    this.cookiesFilePath = '',
    this.useTorProxy = false,
  });

  AppSettings copyWith({
    String? themeMode,
    bool? audioOnly,
    bool? autoStart,
    int? maxConcurrent,
    String? outputFolder,
    String? preferredQuality,
    String? outputFormat,
    String? audioFormat,
    bool? embedThumbnail,
    bool? embedSubtitles,
    bool? twitterIncludeReplies,
    bool? twitchDownloadChat,
    String? twitchQuality,
    bool? adultSitesEnabled,
    String? cookiesFilePath,
    bool? useTorProxy,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      audioOnly: audioOnly ?? this.audioOnly,
      autoStart: autoStart ?? this.autoStart,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      outputFolder: outputFolder ?? this.outputFolder,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      outputFormat: outputFormat ?? this.outputFormat,
      audioFormat: audioFormat ?? this.audioFormat,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      twitterIncludeReplies:
          twitterIncludeReplies ?? this.twitterIncludeReplies,
      twitchDownloadChat: twitchDownloadChat ?? this.twitchDownloadChat,
      twitchQuality: twitchQuality ?? this.twitchQuality,
      adultSitesEnabled: adultSitesEnabled ?? this.adultSitesEnabled,
      cookiesFilePath: cookiesFilePath ?? this.cookiesFilePath,
      useTorProxy: useTorProxy ?? this.useTorProxy,
    );
  }
}

// Keys
const _kThemeMode = 'theme_mode';
const _kAudioOnly = 'audio_only';
const _kAutoStart = 'auto_start';
const _kMaxConcurrent = 'max_concurrent';
const _kOutputFolder = 'output_folder';
const _kPreferredQuality = 'preferred_quality';
const _kOutputFormat = 'output_format';
const _kAudioFormat = 'audio_format';
const _kEmbedThumbnail = 'embed_thumbnail';
const _kEmbedSubtitles = 'embed_subtitles';
const _kTwitterIncludeReplies = 'twitter_include_replies';
const _kTwitchDownloadChat = 'twitch_download_chat';
const _kTwitchQuality = 'twitch_quality';
const _kAdultSitesEnabled = 'adult_sites_enabled';
const _kCookiesFilePath = 'cookies_file_path';
const _kUseTorProxy = 'use_tor_proxy';

/// Global SharedPreferences instance holder
SharedPreferences? _prefsInstance;

void initPrefs(SharedPreferences prefs) {
  _prefsInstance = prefs;
}

SharedPreferences get prefs {
  if (_prefsInstance == null) {
    throw StateError(
      'SharedPreferences not initialized. Call initPrefs() in main.',
    );
  }
  return _prefsInstance!;
}

/// Settings Notifier with persistence
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    state = AppSettings(
      themeMode: prefs.getString(_kThemeMode) ?? 'system',
      audioOnly: prefs.getBool(_kAudioOnly) ?? false,
      autoStart: prefs.getBool(_kAutoStart) ?? true,
      maxConcurrent: prefs.getInt(_kMaxConcurrent) ?? 3,
      outputFolder: prefs.getString(_kOutputFolder) ?? '',
      preferredQuality: prefs.getString(_kPreferredQuality) ?? 'best',
      outputFormat: prefs.getString(_kOutputFormat) ?? 'mp4',
      audioFormat: prefs.getString(_kAudioFormat) ?? 'mp3',
      embedThumbnail: prefs.getBool(_kEmbedThumbnail) ?? true,
      embedSubtitles: prefs.getBool(_kEmbedSubtitles) ?? false,
      twitterIncludeReplies: prefs.getBool(_kTwitterIncludeReplies) ?? false,
      twitchDownloadChat: prefs.getBool(_kTwitchDownloadChat) ?? false,
      twitchQuality: prefs.getString(_kTwitchQuality) ?? '1080p60',
      adultSitesEnabled: prefs.getBool(_kAdultSitesEnabled) ?? false,
      cookiesFilePath: prefs.getString(_kCookiesFilePath) ?? '',
      useTorProxy: prefs.getBool(_kUseTorProxy) ?? false,
    );
  }

  void setThemeMode(String value) {
    state = state.copyWith(themeMode: value);
    prefs.setString(_kThemeMode, value);
  }

  void setAudioOnly(bool value) {
    state = state.copyWith(audioOnly: value);
    prefs.setBool(_kAudioOnly, value);
  }

  void setAutoStart(bool value) {
    state = state.copyWith(autoStart: value);
    prefs.setBool(_kAutoStart, value);
  }

  void setMaxConcurrent(int value) {
    state = state.copyWith(maxConcurrent: value);
    prefs.setInt(_kMaxConcurrent, value);
  }

  void setOutputFolder(String value) {
    state = state.copyWith(outputFolder: value);
    prefs.setString(_kOutputFolder, value);
  }

  void setPreferredQuality(String value) {
    state = state.copyWith(preferredQuality: value);
    prefs.setString(_kPreferredQuality, value);
  }

  void setOutputFormat(String value) {
    state = state.copyWith(outputFormat: value);
    prefs.setString(_kOutputFormat, value);
  }

  void setAudioFormat(String value) {
    state = state.copyWith(audioFormat: value);
    prefs.setString(_kAudioFormat, value);
  }

  void setEmbedThumbnail(bool value) {
    state = state.copyWith(embedThumbnail: value);
    prefs.setBool(_kEmbedThumbnail, value);
  }

  void setEmbedSubtitles(bool value) {
    state = state.copyWith(embedSubtitles: value);
    prefs.setBool(_kEmbedSubtitles, value);
  }

  void setTwitterIncludeReplies(bool value) {
    state = state.copyWith(twitterIncludeReplies: value);
    prefs.setBool(_kTwitterIncludeReplies, value);
  }

  void setTwitchDownloadChat(bool value) {
    state = state.copyWith(twitchDownloadChat: value);
    prefs.setBool(_kTwitchDownloadChat, value);
  }

  void setTwitchQuality(String value) {
    state = state.copyWith(twitchQuality: value);
    prefs.setString(_kTwitchQuality, value);
  }

  void setAdultSitesEnabled(bool value) {
    state = state.copyWith(adultSitesEnabled: value);
    prefs.setBool(_kAdultSitesEnabled, value);
  }

  void setCookiesFilePath(String value) {
    state = state.copyWith(cookiesFilePath: value);
    prefs.setString(_kCookiesFilePath, value);
  }

  void setUseTorProxy(bool value) {
    state = state.copyWith(useTorProxy: value);
    prefs.setBool(_kUseTorProxy, value);
  }

  void clearCookies() {
    state = state.copyWith(cookiesFilePath: '');
    prefs.remove(_kCookiesFilePath);
  }
}

/// Global settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
