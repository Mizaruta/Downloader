import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        // background: AppColors.background, // Deprecated
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        // onBackground: AppColors.textPrimary, // Deprecated
        onError: Colors.white,
      ),

      // Typography
      textTheme: AppTypography.textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,

      // Components Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 18),

      // Card Theme (Commented out to fix type error)
      // cardTheme: CardTheme(
      //   color: AppColors.surface,
      //   elevation: 0,
      //   margin: EdgeInsets.zero,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(8),
      //     side: const BorderSide(color: AppColors.border, width: 1),
      //   ),
      // ),

      // Input Decoration (Text Fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1,
          ), // Subtle focus
        ),
        hintStyle: TextStyle(
          color: AppColors.textDisabled,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }

  static ThemeData get lightTheme {
    // For now, mirroring dark theme or providing a basic light theme structure
    // Since we prioritized Dark Mode, we can just return a lighter version or
    // for MVP consistency, return the same structure with lighter colors if we had them.
    // Spec said "Dark theme focus".
    // Let's return a basic light theme to avoid errors, but keep it minimal.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }
}
