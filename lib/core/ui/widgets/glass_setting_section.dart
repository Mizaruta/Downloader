import 'package:flutter/material.dart';
import 'package:modern_downloader/theme/ios_theme.dart';
import 'package:modern_downloader/theme/palette.dart';
import 'package:gap/gap.dart';

class GlassSettingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final Widget? headerExtra;

  const GlassSettingSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: IOSTheme.glassDecoration(
        color: Palette.glassWhite,
        borderColor: Palette.borderWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildIcon(),
                const Gap(12),
                Expanded(
                  child: Text(
                    title,
                    style: IOSTheme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                if (headerExtra != null) headerExtra!,
              ],
            ),
          ),
          Divider(height: 1, color: Palette.borderWhite),
          // Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}
