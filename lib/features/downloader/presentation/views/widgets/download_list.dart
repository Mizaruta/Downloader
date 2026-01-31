import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../core/design_system/foundation/colors.dart';
import '../../../../../core/design_system/foundation/spacing.dart';
import '../../../../../core/design_system/foundation/typography.dart';
import '../../../../../core/design_system/components/app_card.dart';

import '../../../../../core/design_system/components/status_badge.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/enums/download_status.dart';
import '../../providers/filtered_downloads_provider.dart';
import '../../providers/downloader_provider.dart';
import 'download_item_skeleton.dart';

class DownloadList extends ConsumerWidget {
  const DownloadList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(downloadSearchQueryProvider);
    final statusFilter = ref.watch(downloadStatusFilterProvider);
    final isReorderEnabled =
        searchQuery.isEmpty && statusFilter == DownloadStatusFilter.all;

    final downloadsAsync = ref.watch(filteredDownloadsProvider);
    final selectedId = ref.watch(selectedDownloadIdProvider);
    final viewMode = ref.watch(downloadViewModeProvider);

    return downloadsAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: 5,
        separatorBuilder: (ctx, i) => const Gap(AppSpacing.s),
        itemBuilder: (context, index) => const DownloadItemSkeleton(),
      ),

      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const Gap(AppSpacing.m),
            Text(
              "Error loading downloads",
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            const Gap(AppSpacing.s),
            Text(
              error.toString(),
              style: AppTypography.caption.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (downloads) {
        if (downloads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const Gap(AppSpacing.m),
                Text(
                  "No downloads found",
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (viewMode == DownloadViewMode.detailed) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 280,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
            ),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final item = downloads[index];
              final isSelected = item.id == selectedId;
              return _DownloadItemGridCard(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedDownloadIdProvider.notifier).state = item.id;
                },
                onRetry: () =>
                    ref.read(downloadListProvider.notifier).retryDownload(item),
                onCancel: () => ref
                    .read(downloadListProvider.notifier)
                    .deleteDownload(item.id),
              );
            },
          );
        }

        if (!isReorderEnabled) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: downloads.length,
            separatorBuilder: (ctx, i) => const Gap(AppSpacing.s),
            itemBuilder: (context, index) {
              final item = downloads[index];
              final isSelected = item.id == selectedId;
              return _DownloadItemCard(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedDownloadIdProvider.notifier).state = item.id;
                },
                onRetry: () =>
                    ref.read(downloadListProvider.notifier).retryDownload(item),
                onCancel: () => ref
                    .read(downloadListProvider.notifier)
                    .deleteDownload(item.id),
              );
            },
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: downloads.length,
          proxyDecorator: (widget, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue = Curves.easeInOut.transform(
                  animation.value,
                );
                final double elevation = lerpDouble(0, 6, animValue)!;
                return Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  shadowColor: Colors.black.withValues(alpha: 0.5),
                  child: widget,
                );
              },
              child: widget,
            );
          },
          onReorder: (oldIndex, newIndex) {
            ref.read(downloadListProvider.notifier).reorder(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final item = downloads[index];
            final isSelected = item.id == selectedId;

            return Container(
              key: ValueKey(item.id),
              margin: const EdgeInsets.only(bottom: AppSpacing.s),
              child: _DownloadItemCard(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  ref.read(selectedDownloadIdProvider.notifier).state = item.id;
                },
                onRetry: () =>
                    ref.read(downloadListProvider.notifier).retryDownload(item),
                onCancel: () => ref
                    .read(downloadListProvider.notifier)
                    .deleteDownload(item.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _DownloadItemGridCard extends StatelessWidget {
  final DownloadItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _DownloadItemGridCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDownloading = item.status == DownloadStatus.downloading;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview Area
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnailUrl != null)
                    _buildThumbnailImage(item.thumbnailUrl!)
                  else
                    const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    ),

                  // Status Overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadge(status: item.status, error: item.error),
                  ),

                  // Progress Overlay
                  if (isDownloading)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: item.progress > 0 ? item.progress : null,
                        backgroundColor: Colors.transparent,
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Info Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? "Unknown Title",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Meta info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.source,
                              style: AppTypography.mono.copyWith(fontSize: 10),
                            ),
                            const Gap(2),
                            Text(
                              isDownloading && item.speed.isNotEmpty
                                  ? item.speed
                                  : (item.totalSize.isNotEmpty
                                        ? item.totalSize
                                        : "Unknown Size"),
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      if (item.status == DownloadStatus.failed ||
                          item.status == DownloadStatus.canceled)
                        Row(
                          children: [
                            IconButton(
                              onPressed: onRetry,
                              icon: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: onCancel,
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to display thumbnail from local file or network URL
  Widget _buildThumbnailImage(String url) {
    // Only treat as network URL if it explicitly starts with http:// or https://
    final isNetworkUrl =
        url.startsWith('http://') || url.startsWith('https://');

    if (isNetworkUrl) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
        ),
      );
    }

    // Everything else is treated as a local file path
    // Decode URL-encoded paths if needed
    String decodedPath = url;
    try {
      decodedPath = Uri.decodeFull(url);
    } catch (_) {}

    final file = File(decodedPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
        ),
      );
    }

    // File doesn't exist - show placeholder
    return const Center(
      child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
    );
  }
}

class _DownloadItemCard extends StatelessWidget {
  final DownloadItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _DownloadItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDownloading = item.status == DownloadStatus.downloading;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          // Thumbnail / Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.thumbnailUrl != null
                ? _buildThumbnailImage(item.thumbnailUrl!)
                : const Icon(
                    Icons.movie_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
          ),
          const Gap(AppSpacing.m),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (item.title == null || item.title!.isEmpty)
                            ? "Unknown Title"
                            : item.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.s),
                    StatusBadge(status: item.status, error: item.error),
                  ],
                ),

                const Gap(4),

                // Meta Row or Progress
                if (isDownloading ||
                    item.status == DownloadStatus.extracting) ...[
                  const Gap(4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.progress > 0 ? item.progress : null,
                      backgroundColor: AppColors.background,
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                  const Gap(6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${(item.progress * 100).toStringAsFixed(1)}%",
                        style: AppTypography.mono.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const Gap(8),
                      Flexible(
                        child: Text(
                          _buildMetaString(),
                          style: AppTypography.mono,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    _buildMetaString(),
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Action Buttons
          if (item.status == DownloadStatus.failed ||
              item.status == DownloadStatus.canceled) ...[
            const Gap(AppSpacing.s),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: "Retry Download",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              tooltip: "Remove",
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ],
        ],
      ),
    );
  }

  String _buildMetaString() {
    final parts = <String>[];

    // Source
    parts.add(item.source);

    // Size logic
    if (item.totalSize.isNotEmpty) {
      if (item.downloadedSize.isNotEmpty &&
          item.status == DownloadStatus.downloading) {
        parts.add("${item.downloadedSize} / ${item.totalSize}");
      } else {
        parts.add(item.totalSize);
      }
    } else if (item.downloadedSize.isNotEmpty) {
      parts.add(item.downloadedSize);
    }

    // Speed
    if (item.speed.isNotEmpty && item.status == DownloadStatus.downloading) {
      parts.add(item.speed);
    }

    // ETA
    if (item.eta.isNotEmpty && item.status == DownloadStatus.downloading) {
      parts.add("ETA ${item.eta}");
    }

    return parts.join(" • ");
  }

  /// Helper method to display thumbnail from local file or network URL
  Widget _buildThumbnailImage(String url) {
    // Only treat as network URL if it explicitly starts with http:// or https://
    final isNetworkUrl =
        url.startsWith('http://') || url.startsWith('https://');

    if (isNetworkUrl) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.movie_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
      );
    }

    // Everything else is treated as a local file path
    // Decode URL-encoded paths if needed
    String decodedPath = url;
    try {
      decodedPath = Uri.decodeFull(url);
    } catch (_) {}

    final file = File(decodedPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.movie_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
      );
    }

    // File doesn't exist - show placeholder
    return const Icon(
      Icons.movie_outlined,
      color: AppColors.textSecondary,
      size: 24,
    );
  }
}
