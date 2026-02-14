import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../design_system/foundation/colors.dart';
import '../../design_system/foundation/spacing.dart';
import '../../design_system/foundation/typography.dart';
import '../../plugins/plugin_manager.dart';

class PluginsSettingsView extends ConsumerWidget {
  const PluginsSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginState = ref.watch(pluginManagerProvider);
    final pluginManager = ref.read(pluginManagerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const SizedBox(),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(
          "Plugins",
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xl + 20,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: !pluginState.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : pluginState.plugins.isEmpty
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pluginState.plugins
                        .map(
                          (entry) => _PluginCard(
                            entry: entry,
                            onToggle: (enabled) {
                              pluginManager.togglePlugin(
                                entry.plugin.id,
                                enabled,
                              );
                            },
                          ),
                        )
                        .toList()
                        .animate(interval: 80.ms)
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.1, end: 0, duration: 300.ms),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap(80),
          Icon(
            Icons.extension_off_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const Gap(AppSpacing.m),
          Text(
            "No plugins installed",
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(AppSpacing.xs),
          Text(
            "Plugins extend the functionality of Modern Downloader",
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  final PluginEntry entry;
  final ValueChanged<bool> onToggle;

  const _PluginCard({required this.entry, required this.onToggle});

  IconData _getIcon(String name) {
    switch (name) {
      case 'drive_file_rename_outline':
        return Icons.drive_file_rename_outline;
      case 'extension':
        return Icons.extension;
      default:
        return Icons.extension;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isEnabled
              ? AppColors.border
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.isEnabled
                  ? AppColors.surfaceHighlight
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIcon(entry.plugin.iconName),
              color: entry.isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
              size: 22,
            ),
          ),
          const Gap(AppSpacing.m),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.plugin.name,
                      style: AppTypography.label.copyWith(
                        color: entry.isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v${entry.plugin.version}',
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    ),
                    if (entry.plugin.isBuiltIn) ...[
                      const Gap(AppSpacing.xxs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Built-in',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(AppSpacing.xxs),
                Text(
                  entry.plugin.description,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.error != null) ...[
                  const Gap(AppSpacing.xxs),
                  Text(
                    'Error: ${entry.error}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Settings Button (if applicable)
          if (entry.plugin.id == 'builtin_smart_organizer') ...[
            IconButton(
              icon: const Icon(
                Icons.build_circle_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => context.push('/settings/smart_organizer'),
              tooltip: "Configure Plugin",
            ),
            const Gap(AppSpacing.s),
          ],

          // Toggle
          Switch(
            value: entry.isEnabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.success,
            inactiveThumbColor: AppColors.textDisabled,
            inactiveTrackColor: AppColors.surfaceHighlight,
          ),
        ],
      ),
    );
  }
}
