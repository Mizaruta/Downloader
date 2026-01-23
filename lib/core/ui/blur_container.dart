import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:modern_downloader/theme/ios_theme.dart';

class BlurContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;

  const BlurContainer({
    super.key,
    required this.child,
    this.borderRadius = IOSTheme.kRadiusLarge,
    this.blurSigma = 20.0,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // If interactive, use proper touch feedback container
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: IOSTheme.glassDecoration(
            radius: borderRadius,
            color: color ?? const Color(0x1F252525), // Dark glass base
          ),
          child: child,
        ),
      ),
    );

    if (onPressed != null) {
      return GestureDetector(onTap: onPressed, child: content);
    }

    return content;
  }
}
