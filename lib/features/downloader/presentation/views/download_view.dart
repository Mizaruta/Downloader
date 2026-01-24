import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modern_downloader/core/theme/app_colors.dart';
import '../../presentation/providers/filtered_downloads_provider.dart';

import 'inspector/download_inspector.dart';
import 'widgets/download_list.dart';

class DownloadView extends ConsumerWidget {
  const DownloadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3-Column Layout: [Sidebar (handled by Shell)] [Main List] [Inspector]
    return Row(
      children: [
        // Main Content (List)
        Expanded(
          child: Column(
            children: [
              // Top Bar (Search / Filter)
              const _DownloadTopBar(),

              // Divider
              const Divider(height: 1, color: AppColors.border),

              // List
              const Expanded(child: DownloadList()),
            ],
          ),
        ),

        // Inspector Panel (Conditional or Always visible but empty?)
        // Design Doc says "Inspector appears on selection".
        // We will show it if an item is selected.
        Consumer(
          builder: (context, ref, child) {
            final selectedId = ref.watch(selectedDownloadIdProvider);
            if (selectedId == null) return const SizedBox.shrink();

            return Container(
              width: 300,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border)),
                color: AppColors.surface,
              ),
              child: DownloadInspector(downloadId: selectedId),
            );
          },
        ),
      ],
    );
  }
}

class _DownloadTopBar extends ConsumerWidget {
  const _DownloadTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: _SearchBar(
              onChanged: (value) {
                ref.read(downloadSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 16),
          // Filter Button
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.filter_list,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: "Filter",
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to import the provider
    // Since I cannot easily add top-level imports in this specific Replace call without context of line 1-10
    // I will assume the previous imports are there, and I will add the import in a separate tool call if needed or use the providers directly if visible.

    // Actually, I'll update the user of this search bar to update the provider.
    return Container(
      height: 32,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: "Search downloads...",
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.zero, // Important for centering in small height
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
