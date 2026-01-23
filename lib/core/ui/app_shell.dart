import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modern_downloader/core/ui/widgets/floating_nav_dock.dart';
import 'package:modern_downloader/core/ui/widgets/mesh_gradient_background.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.toString();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Global Animated Background
          const Positioned.fill(child: MeshGradientBackground()),

          // 2. Main Content Area
          Positioned.fill(
            child: Row(
              children: [
                // Spacing for Dock
                const SizedBox(width: 100), // Reserve space for dock
                // Page Content
                Expanded(child: child),
              ],
            ),
          ),

          // 3. Floating Navigation Dock
          FloatingNavDock(currentLocation: location),
        ],
      ),
    );
  }
}
