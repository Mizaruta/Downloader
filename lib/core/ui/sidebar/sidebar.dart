import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../design_system/foundation/colors.dart';
import '../../design_system/foundation/spacing.dart';
import '../../design_system/foundation/typography.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_skeleton.dart';
import '../../../../features/downloader/presentation/views/dialogs/add_download_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/downloader/presentation/providers/filtered_downloads_provider.dart';
import '../../../../features/downloader/presentation/providers/downloader_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../features/downloader/domain/enums/download_status.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch relevant state
    final statusFilter = ref.watch(downloadStatusFilterProvider);
    final sourceFilter = ref.watch(downloadSourceFilterProvider);
    final allDownloadsAsync = ref.watch(downloadListProvider);
    final allDownloads = allDownloadsAsync.valueOrNull ?? [];
    final settings = ref.watch(settingsProvider);

    // Calculate Counts
    final countActive = allDownloads
        .where(
          (i) =>
              i.status == DownloadStatus.downloading ||
              i.status == DownloadStatus.queued ||
              i.status == DownloadStatus.extracting ||
              i.status == DownloadStatus.processing,
        )
        .length;
    final countCompleted = allDownloads
        .where((i) => i.status == DownloadStatus.completed)
        .length;
    final countFailed = allDownloads
        .where(
          (i) =>
              i.status == DownloadStatus.failed ||
              i.status == DownloadStatus.canceled,
        )
        .length;

    // Determine Sources
    final Map<String, int> sourceCounts = {};
    for (var item in allDownloads) {
      sourceCounts[item.source] = (sourceCounts[item.source] ?? 0) + 1;
    }

    final List<String> availableSources = [
      'YouTube',
      'Instagram',
      'Twitter',
      'Twitch',
      'Kick',
    ];

    // Add dynamically discovered sources
    for (var source in sourceCounts.keys) {
      // Basic Adult Filtering
      if (!settings.adultSitesEnabled) {
        const adultKeywords = [
          'Pornhub',
          'Xvideos',
          'Xhamster',
          'Youporn',
          'Xnxx',
          'Chaturbate',
          'Onlyfans',
        ];
        if (adultKeywords.contains(source)) continue;
      }

      if (!availableSources.contains(source) && source != 'Other') {
        availableSources.add(source);
      }
    }

    void setStatus(DownloadStatusFilter status) {
      ref.read(downloadStatusFilterProvider.notifier).state = status;
      ref.read(downloadSourceFilterProvider.notifier).state =
          null; // Reset source
    }

    void setSource(String? source) {
      ref.read(downloadSourceFilterProvider.notifier).state = source;
      ref.read(downloadStatusFilterProvider.notifier).state =
          DownloadStatusFilter.all; // Reset status
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.m,
      ),
      child: Column(
        children: [
          // Primary Action
          AppButton.primary(
            label: "New Download",
            icon: Icons.add,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddDownloadDialog(),
              );
            },
          ),

          const Gap(AppSpacing.l),

          const Gap(AppSpacing.l),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _NavSection(
                    title: "LIBRARY",
                    children: [
                      _NavItem(
                        icon: Icons.inbox_rounded,
                        label: "All Downloads",
                        count: allDownloads.length,
                        isLoading: allDownloadsAsync.isLoading,
                        isSelected:
                            statusFilter == DownloadStatusFilter.all &&
                            sourceFilter == null,
                        onTap: () => setStatus(DownloadStatusFilter.all),
                      ),
                      _NavItem(
                        icon: Icons.downloading_rounded,
                        label: "Active",
                        count: countActive,
                        isLoading: allDownloadsAsync.isLoading,
                        isSelected: statusFilter == DownloadStatusFilter.active,
                        onTap: () => setStatus(DownloadStatusFilter.active),
                      ),
                      _NavItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: "Completed",
                        count: countCompleted,
                        isLoading: allDownloadsAsync.isLoading,
                        isSelected:
                            statusFilter == DownloadStatusFilter.completed,
                        onTap: () => setStatus(DownloadStatusFilter.completed),
                      ),
                      _NavItem(
                        icon: Icons.error_outline_rounded,
                        label: "Failed",
                        count: countFailed,
                        isLoading: allDownloadsAsync.isLoading,
                        isSelected: statusFilter == DownloadStatusFilter.failed,
                        onTap: () => setStatus(DownloadStatusFilter.failed),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.l),
                  _NavSection(
                    title: "SOURCES",
                    children: allDownloadsAsync.isLoading
                        ? List.generate(
                            3,
                            (index) => const Padding(
                              padding: EdgeInsets.only(
                                bottom: 8,
                                left: 12,
                                right: 12,
                              ),
                              child: AppSkeleton(
                                height: 24,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                            ),
                          )
                        : availableSources.map((source) {
                            // Icon mapping
                            IconData icon = Icons.public;
                            if (source == 'YouTube') {
                              icon = Icons.video_library_outlined;
                            } else if (source == 'Instagram') {
                              icon = Icons.photo_camera_outlined;
                            } else if (source == 'Twitter') {
                              icon = Icons.alternate_email;
                            } else if (source == 'Twitch') {
                              icon = Icons.videogame_asset_outlined;
                            } else if (source == 'Kick') {
                              icon = Icons.bolt;
                            }

                            return _NavItem(
                              icon: icon,
                              label: source,
                              count: sourceCounts[source] ?? 0,
                              isLoading:
                                  false, // Sources loaded implies data loaded
                              isSelected: sourceFilter == source,
                              onTap: () => setSource(source),
                            );
                          }).toList(),
                  ),
                  const Gap(AppSpacing.l),
                ],
              ),
            ),
          ),

          // Bottom Actions
          _NavItem(
            icon: Icons.settings_outlined,
            label: "Settings",
            isSelected: false,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NavSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Text(
            title,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Gap(AppSpacing.xxs),
        ...children,
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;
  final bool isLoading;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
    this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBorder,
        hoverColor: AppColors.surfaceHighlight,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceHighlight : Colors.transparent,
            borderRadius: AppRadius.mediumBorder,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const Gap(AppSpacing.s),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (isLoading)
                const AppSkeleton(
                  width: 24,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                )
              else if (count != null && count! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.surfaceHighlight,
                    borderRadius: AppRadius.fullBorder,
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
