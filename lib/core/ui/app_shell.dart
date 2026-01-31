import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:modern_downloader/core/theme/app_colors.dart';
import 'package:modern_downloader/core/providers/launch_provider.dart';
import 'package:modern_downloader/features/downloader/presentation/views/dialogs/add_download_dialog.dart';
import 'package:modern_downloader/features/downloader/presentation/providers/downloader_provider.dart';
import 'sidebar/sidebar.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for deep link launches (Global)
    ref.listen<LaunchData?>(launchDataProvider, (previous, next) {
      if (next != null) {
        _handleLaunchData(context, ref, next);
      }
    });

    // Check for initial URL (Cold Start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final initialData = ref.read(launchDataProvider);
      if (initialData != null) {
        _handleLaunchData(context, ref, initialData);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Windows Title Bar (Draggable)
          const AppTitleBar(),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar
                const SizedBox(width: 250, child: AppSidebar()),

                // Vertical Divider
                Container(width: 1, color: AppColors.border),

                // Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLaunchData(BuildContext context, WidgetRef ref, LaunchData data) {
    // Clear the provider to prevent re-triggering
    ref.read(launchDataProvider.notifier).state = null;

    if (data.shouldAutoStart) {
      // Direct start for extensions
      ref
          .read(downloadListProvider.notifier)
          .startDownload(
            data.url,
            rawCookies: data.cookies,
            userAgent: data.userAgent,
            cookieBrowser: data.cookieBrowser,
          );

      // We still need context for Toast
      try {
        // Simple success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Extension: Download started for ${data.url}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      } catch (e) {
        // Fallback for cold start where context might be tricky
      }
      return;
    }

    // Show the dialog with the URL and cookies (Deep link fallback)
    showDialog(
      context: context,
      builder: (context) => AddDownloadDialog(
        initialUrl: data.url,
        initialCookies: data.cookies,
        userAgent: data.userAgent,
      ),
    );
  }
}

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: AppColors.background,
      child: Row(
        children: [
          // Draggable Area (Takes remaining space)
          Expanded(
            child: DragToMoveArea(
              child: Container(
                color: Colors.transparent, // Hit test target
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "", // Title could go here
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ),

          // Window Controls (Non-draggable, Top-Right)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _WindowButton(
                  color: const Color(0xFFFFBD2E), // Yellow (Min)
                  onTap: () {
                    windowManager.minimize();
                  },
                  icon: Icons.minimize,
                ),
                const SizedBox(width: 8),
                _WindowButton(
                  color: const Color(0xFF28C940), // Green (Max)
                  onTap: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                  icon: Icons.crop_square,
                ),
                const SizedBox(width: 8),
                _WindowButton(
                  color: const Color(0xFFFF5F57), // Red (Close)
                  onTap: () {
                    windowManager.close();
                  },
                  icon: Icons.close,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final IconData icon;

  const _WindowButton({
    required this.color,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: _isHovering
              ? Center(
                  child: Icon(
                    widget.icon,
                    size: 10,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
