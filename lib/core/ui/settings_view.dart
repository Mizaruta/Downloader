import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modern_downloader/theme/ios_theme.dart';
import 'package:modern_downloader/theme/palette.dart';
import 'package:modern_downloader/core/ui/widgets/glass_setting_section.dart';
import '../../services/binary_verifier.dart';
import '../providers/settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  // Binary status
  BinaryStatus? _ytDlpStatus;
  BinaryStatus? _ffmpegStatus;
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: IOSTheme.textTheme.displayLarge,
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                    const Gap(8),
                    Text(
                      'Customize your download experience',
                      style: IOSTheme.textTheme.bodyMedium?.copyWith(
                        color: Palette.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // General
                  GlassSettingSection(
                    title: 'General',
                    icon: Icons.tune_rounded,
                    iconColor: Palette.neonBlue,
                    children: [
                      _buildSwitchTile(
                        title: 'Audio Only',
                        subtitle: 'Extract audio as MP3',
                        value: settings.audioOnly,
                        onChanged: settingsNotifier.setAudioOnly,
                      ),
                      _buildSwitchTile(
                        title: 'Auto-Start Downloads',
                        subtitle: 'Start immediately when link is pasted',
                        value: settings.autoStart,
                        onChanged: settingsNotifier.setAutoStart,
                      ),
                      _buildSliderTile(
                        title: 'Concurrent Downloads',
                        value: settings.maxConcurrent,
                        min: 1,
                        max: 5,
                        onChanged: (v) =>
                            settingsNotifier.setMaxConcurrent(v.round()),
                      ),
                      _buildDropdownTile(
                        title: 'Preferred Quality',
                        value: settings.preferredQuality,
                        options: const [
                          'best',
                          '1080p',
                          '720p',
                          '480p',
                          '360p',
                          'worst',
                        ],
                        onChanged: settingsNotifier.setPreferredQuality,
                      ),
                      _buildDropdownTile(
                        title: 'Output Format',
                        value: settings.outputFormat,
                        options: const ['mp4', 'mkv', 'webm'],
                        onChanged: settingsNotifier.setOutputFormat,
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  // Streaming
                  GlassSettingSection(
                    title: 'Streaming',
                    icon: Icons.videocam_rounded,
                    iconColor: Palette.neonPurple,
                    children: [
                      _buildSiteToggle(
                        name: 'Twitch Chat',
                        isEnabled: settings.twitchDownloadChat,
                        onChanged: settingsNotifier.setTwitchDownloadChat,
                      ),
                      _buildDropdownTile(
                        title: 'Twitch Quality',
                        value: settings.twitchQuality,
                        options: const [
                          'source',
                          '1080p60',
                          '1080p',
                          '720p60',
                          '720p',
                          '480p',
                        ],
                        onChanged: settingsNotifier.setTwitchQuality,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  // Social Media
                  GlassSettingSection(
                    title: 'Social Media',
                    icon: Icons.share_rounded,
                    iconColor: Palette.neonPink,
                    children: [
                      _buildSiteToggle(
                        name: 'Twitter Replies',
                        isEnabled: settings.twitterIncludeReplies,
                        onChanged: settingsNotifier.setTwitterIncludeReplies,
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  // Adult Sites
                  GlassSettingSection(
                    title: 'Adult Sites',
                    icon: Icons.eighteen_up_rating_rounded,
                    iconColor: Palette.error,
                    headerExtra: CupertinoSwitch(
                      value: settings.adultSitesEnabled,
                      onChanged: settingsNotifier.setAdultSitesEnabled,
                      activeTrackColor: Palette.error,
                    ),
                    children: settings.adultSitesEnabled
                        ? [
                            _buildSwitchTile(
                              title: 'Use Tor Proxy',
                              subtitle: 'Bypass blocks (127.0.0.1:9050)',
                              value: settings.useTorProxy,
                              onChanged: settingsNotifier.setUseTorProxy,
                            ),
                            _buildActionTile(
                              title: 'Cookies File',
                              subtitle: settings.cookiesFilePath.isEmpty
                                  ? 'Select cookies.txt'
                                  : settings.cookiesFilePath,
                              onTap: () => _pickCookiesFile(settingsNotifier),
                              icon: Icons.cookie_rounded,
                            ),
                          ]
                        : [],
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                  // Output
                  GlassSettingSection(
                    title: 'Output',
                    icon: Icons.folder_rounded,
                    iconColor: Palette.warning,
                    children: [
                      _buildActionTile(
                        title: 'Download Folder',
                        subtitle: settings.outputFolder.isEmpty
                            ? 'Not selected'
                            : settings.outputFolder,
                        onTap: () => _pickOutputFolder(settingsNotifier),
                        icon: Icons.folder_open_rounded,
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                  // System
                  GlassSettingSection(
                    title: 'System',
                    icon: Icons.settings_rounded,
                    iconColor: Palette.textSecondary,
                    children: [
                      _buildActionTile(
                        title: 'Verify Dependencies',
                        subtitle: _isVerifying
                            ? 'Checking...'
                            : 'Check yt-dlp & ffmpeg',
                        onTap: _isVerifying ? null : _verifyBinaries,
                        icon: Icons.verified_rounded,
                        trailing: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      if (_ytDlpStatus != null)
                        _buildBinaryStatusTile('yt-dlp', _ytDlpStatus),
                      if (_ffmpegStatus != null)
                        _buildBinaryStatusTile('ffmpeg', _ffmpegStatus),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Version 1.0.0',
                            style: IOSTheme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                  const Gap(80), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tiles ---

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IOSTheme.textTheme.bodyMedium),
                Text(
                  subtitle,
                  style: IOSTheme.textTheme.labelSmall?.copyWith(
                    color: Palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Palette.neonBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSiteToggle({
    required String name,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(name, style: IOSTheme.textTheme.bodyMedium)),
          CupertinoSwitch(
            value: isEnabled,
            onChanged: onChanged,
            activeTrackColor: Palette.neonBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required int value,
    required int min,
    required int max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: IOSTheme.textTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Palette.glassWhiteHover,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toString(),
                  style: IOSTheme.textTheme.labelSmall?.copyWith(
                    color: Palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Palette.neonBlue,
              inactiveTrackColor: Palette.glassWhite,
              thumbColor: Colors.white,
              overlayColor: Palette.neonBlue.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: IOSTheme.textTheme.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Palette.glassWhiteHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Palette.borderWhite, width: 1),
            ),
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              underline: const SizedBox(),
              dropdownColor: Palette.backgroundSoft,
              style: IOSTheme.textTheme.bodyMedium,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Palette.textSecondary,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Palette.glassWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Palette.textSecondary),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: IOSTheme.textTheme.bodyMedium),
                  Text(
                    subtitle,
                    style: IOSTheme.textTheme.labelSmall?.copyWith(
                      color: Palette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Palette.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinaryStatusTile(String name, BinaryStatus? status) {
    if (status == null) return const SizedBox.shrink();
    final isInstalled = status.isInstalled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isInstalled ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isInstalled ? Palette.success : Palette.error,
            size: 20,
          ),
          const Gap(12),
          Text(name, style: IOSTheme.textTheme.bodyMedium),
          const Spacer(),
          if (status.version != null)
            Text(status.version!, style: IOSTheme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Future<void> _pickOutputFolder(SettingsNotifier notifier) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      notifier.setOutputFolder(selectedDirectory);
    }
  }

  Future<void> _pickCookiesFile(SettingsNotifier notifier) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      notifier.setCookiesFilePath(result.files.single.path!);
    }
  }

  Future<void> _verifyBinaries() async {
    setState(() => _isVerifying = true);
    final ytdlp = await BinaryVerifier.checkYtDlp();
    final ffmpeg = await BinaryVerifier.checkFfmpeg();
    if (mounted) {
      setState(() {
        _ytDlpStatus = ytdlp;
        _ffmpegStatus = ffmpeg;
        _isVerifying = false;
      });
    }
  }
}
