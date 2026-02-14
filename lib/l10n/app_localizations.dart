import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Modern Downloader'**
  String get appTitle;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get plugins;

  /// No description provided for @newDownload.
  ///
  /// In en, this message translates to:
  /// **'New Download'**
  String get newDownload;

  /// No description provided for @pasteUrl.
  ///
  /// In en, this message translates to:
  /// **'Paste URL here'**
  String get pasteUrl;

  /// No description provided for @startDownload.
  ///
  /// In en, this message translates to:
  /// **'Start Download'**
  String get startDownload;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @statusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get statusQueued;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get statusDownloading;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting'**
  String get statusExtracting;

  /// No description provided for @statusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get statusDuplicate;

  /// No description provided for @sidebarAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sidebarAll;

  /// No description provided for @sidebarActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sidebarActive;

  /// No description provided for @sidebarCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sidebarCompleted;

  /// No description provided for @sidebarFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sidebarFailed;

  /// No description provided for @sidebarBySource.
  ///
  /// In en, this message translates to:
  /// **'By Source'**
  String get sidebarBySource;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get settingsOutput;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @settingsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get settingsPerformance;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsPlugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get settingsPlugins;

  /// No description provided for @audioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio Only'**
  String get audioOnly;

  /// No description provided for @audioOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract audio only (MP3) from videos'**
  String get audioOnlyDesc;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto-Start'**
  String get autoStart;

  /// No description provided for @autoStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Start downloads immediately when added'**
  String get autoStartDesc;

  /// No description provided for @preferredQuality.
  ///
  /// In en, this message translates to:
  /// **'Preferred Quality'**
  String get preferredQuality;

  /// No description provided for @maxConcurrent.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrent Downloads'**
  String get maxConcurrent;

  /// No description provided for @outputFolder.
  ///
  /// In en, this message translates to:
  /// **'Output Folder'**
  String get outputFolder;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get chooseFolder;

  /// No description provided for @useCookies.
  ///
  /// In en, this message translates to:
  /// **'Use Browser Cookies'**
  String get useCookies;

  /// No description provided for @useCookiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Use cookies from your browser for authentication'**
  String get useCookiesDesc;

  /// No description provided for @useProxy.
  ///
  /// In en, this message translates to:
  /// **'Use Proxy'**
  String get useProxy;

  /// No description provided for @useProxyDesc.
  ///
  /// In en, this message translates to:
  /// **'Route downloads through a proxy server'**
  String get useProxyDesc;

  /// No description provided for @minimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get minimizeToTray;

  /// No description provided for @minimizeToTrayDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimize to system tray instead of closing'**
  String get minimizeToTrayDesc;

  /// No description provided for @autoStartApp.
  ///
  /// In en, this message translates to:
  /// **'Start with Windows'**
  String get autoStartApp;

  /// No description provided for @autoStartAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Launch app on system startup'**
  String get autoStartAppDesc;

  /// No description provided for @autoUpdateYtDlp.
  ///
  /// In en, this message translates to:
  /// **'Auto-update yt-dlp'**
  String get autoUpdateYtDlp;

  /// No description provided for @autoUpdateYtDlpDesc.
  ///
  /// In en, this message translates to:
  /// **'Check for yt-dlp updates on startup'**
  String get autoUpdateYtDlpDesc;

  /// No description provided for @showNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show Notifications'**
  String get showNotifications;

  /// No description provided for @showNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Desktop notifications for downloads'**
  String get showNotificationsDesc;

  /// No description provided for @clipboardMonitor.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Monitor'**
  String get clipboardMonitor;

  /// No description provided for @clipboardMonitorDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect URLs from clipboard'**
  String get clipboardMonitorDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageDesc;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose application theme'**
  String get themeDesc;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize the accent color'**
  String get accentColorDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @totalDownloads.
  ///
  /// In en, this message translates to:
  /// **'Total Downloads'**
  String get totalDownloads;

  /// No description provided for @downloadsToday.
  ///
  /// In en, this message translates to:
  /// **'Downloads Today'**
  String get downloadsToday;

  /// No description provided for @totalData.
  ///
  /// In en, this message translates to:
  /// **'Total Data'**
  String get totalData;

  /// No description provided for @freeSpace.
  ///
  /// In en, this message translates to:
  /// **'Free Space'**
  String get freeSpace;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Activity (Last 7 Days)'**
  String get last7Days;

  /// No description provided for @sourceDistribution.
  ///
  /// In en, this message translates to:
  /// **'Source Distribution'**
  String get sourceDistribution;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @newDownloadShortcut.
  ///
  /// In en, this message translates to:
  /// **'New Download'**
  String get newDownloadShortcut;

  /// No description provided for @settingsShortcut.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get settingsShortcut;

  /// No description provided for @dashboardShortcut.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardShortcut;

  /// No description provided for @minimizeShortcut.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimizeShortcut;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @selectDownload.
  ///
  /// In en, this message translates to:
  /// **'Select a download'**
  String get selectDownload;

  /// No description provided for @checkDependencies.
  ///
  /// In en, this message translates to:
  /// **'Check Dependencies'**
  String get checkDependencies;

  /// No description provided for @checkDependenciesDesc.
  ///
  /// In en, this message translates to:
  /// **'Check yt-dlp, ffmpeg & aria2c status'**
  String get checkDependenciesDesc;

  /// No description provided for @verifyingBinaries.
  ///
  /// In en, this message translates to:
  /// **'Verifying binaries...'**
  String get verifyingBinaries;

  /// No description provided for @dependenciesVerified.
  ///
  /// In en, this message translates to:
  /// **'Dependencies verified'**
  String get dependenciesVerified;

  /// No description provided for @organizeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Organize Library'**
  String get organizeLibrary;

  /// No description provided for @organizeLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'Sort files by source, move thumbnails, cleanup temp files'**
  String get organizeLibraryDesc;

  /// No description provided for @organizationComplete.
  ///
  /// In en, this message translates to:
  /// **'Organization Complete'**
  String get organizationComplete;

  /// No description provided for @filesMoved.
  ///
  /// In en, this message translates to:
  /// **'Files moved: {count}'**
  String filesMoved(int count);

  /// No description provided for @filesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Temp files deleted: {count}'**
  String filesDeleted(int count);

  /// No description provided for @noPluginsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No plugins installed'**
  String get noPluginsInstalled;

  /// No description provided for @pluginEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get pluginEnabled;

  /// No description provided for @pluginDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get pluginDisabled;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtIn;

  /// No description provided for @mediaPlayer.
  ///
  /// In en, this message translates to:
  /// **'Media Player'**
  String get mediaPlayer;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
