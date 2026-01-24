import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  const AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF111111); // Main app background
  static const Color surface = Color(0xFF181818); // Sidebar, Cards
  static const Color surfaceHighlight = Color(0xFF222222); // Hover states

  // Accents
  static const Color primary = Color(0xFF6366F1); // Invisible Indigo
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color accent = Color(0xFFFFFFFF); // Clean White accent

  // Text
  static const Color textPrimary = Color(
    0xFFEDEDED,
  ); // Off-white for better reading
  static const Color textSecondary = Color(0xFF888888); // Metadata
  static const Color textDisabled = Color(0xFF444444);

  // Borders & Dividers
  static const Color border = Color(0xFF333333);
  static const Color borderSubtle = Color(0xFF222222);

  // Status
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // Specific UI
  static const Color inputBackground = Color(0xFF1A1A1A);
  static const Color overlay = Color(0x66000000); // 40% Black
}
