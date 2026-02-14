// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Modern Downloader';

  @override
  String get downloads => 'Downloads';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get plugins => 'Plugins';

  @override
  String get newDownload => 'New Download';

  @override
  String get pasteUrl => 'Paste URL here';

  @override
  String get startDownload => 'Start Download';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get delete => 'Delete';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get openFile => 'Open File';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusExtracting => 'Extracting';

  @override
  String get statusDuplicate => 'Duplicate';

  @override
  String get sidebarAll => 'All';

  @override
  String get sidebarActive => 'Active';

  @override
  String get sidebarCompleted => 'Completed';

  @override
  String get sidebarFailed => 'Failed';

  @override
  String get sidebarBySource => 'By Source';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsOutput => 'Output';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsPerformance => 'Performance';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPlugins => 'Plugins';

  @override
  String get audioOnly => 'Audio Only';

  @override
  String get audioOnlyDesc => 'Extract audio only (MP3) from videos';

  @override
  String get autoStart => 'Auto-Start';

  @override
  String get autoStartDesc => 'Start downloads immediately when added';

  @override
  String get preferredQuality => 'Preferred Quality';

  @override
  String get maxConcurrent => 'Max Concurrent Downloads';

  @override
  String get outputFolder => 'Output Folder';

  @override
  String get chooseFolder => 'Choose Folder';

  @override
  String get useCookies => 'Use Browser Cookies';

  @override
  String get useCookiesDesc =>
      'Use cookies from your browser for authentication';

  @override
  String get useProxy => 'Use Proxy';

  @override
  String get useProxyDesc => 'Route downloads through a proxy server';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get minimizeToTrayDesc => 'Minimize to system tray instead of closing';

  @override
  String get autoStartApp => 'Start with Windows';

  @override
  String get autoStartAppDesc => 'Launch app on system startup';

  @override
  String get autoUpdateYtDlp => 'Auto-update yt-dlp';

  @override
  String get autoUpdateYtDlpDesc => 'Check for yt-dlp updates on startup';

  @override
  String get showNotifications => 'Show Notifications';

  @override
  String get showNotificationsDesc => 'Desktop notifications for downloads';

  @override
  String get clipboardMonitor => 'Clipboard Monitor';

  @override
  String get clipboardMonitorDesc => 'Auto-detect URLs from clipboard';

  @override
  String get language => 'Language';

  @override
  String get languageDesc => 'Choose your preferred language';

  @override
  String get theme => 'Theme';

  @override
  String get themeDesc => 'Choose application theme';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get accentColorDesc => 'Customize the accent color';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get totalDownloads => 'Total Downloads';

  @override
  String get downloadsToday => 'Downloads Today';

  @override
  String get totalData => 'Total Data';

  @override
  String get freeSpace => 'Free Space';

  @override
  String get last7Days => 'Activity (Last 7 Days)';

  @override
  String get sourceDistribution => 'Source Distribution';

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get newDownloadShortcut => 'New Download';

  @override
  String get settingsShortcut => 'Open Settings';

  @override
  String get dashboardShortcut => 'Dashboard';

  @override
  String get minimizeShortcut => 'Minimize';

  @override
  String get inspector => 'Inspector';

  @override
  String get title => 'Title';

  @override
  String get status => 'Status';

  @override
  String get progress => 'Progress';

  @override
  String get logs => 'Logs';

  @override
  String get selectDownload => 'Select a download';

  @override
  String get checkDependencies => 'Check Dependencies';

  @override
  String get checkDependenciesDesc => 'Check yt-dlp, ffmpeg & aria2c status';

  @override
  String get verifyingBinaries => 'Verifying binaries...';

  @override
  String get dependenciesVerified => 'Dependencies verified';

  @override
  String get organizeLibrary => 'Organize Library';

  @override
  String get organizeLibraryDesc =>
      'Sort files by source, move thumbnails, cleanup temp files';

  @override
  String get organizationComplete => 'Organization Complete';

  @override
  String filesMoved(int count) {
    return 'Files moved: $count';
  }

  @override
  String filesDeleted(int count) {
    return 'Temp files deleted: $count';
  }

  @override
  String get noPluginsInstalled => 'No plugins installed';

  @override
  String get pluginEnabled => 'Enabled';

  @override
  String get pluginDisabled => 'Disabled';

  @override
  String get builtIn => 'Built-in';

  @override
  String get mediaPlayer => 'Media Player';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get volume => 'Volume';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';
}
