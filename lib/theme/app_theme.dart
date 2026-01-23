import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ios_theme.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: IOSTheme.background,
      primaryColor: IOSTheme.systemBlue,
      canvasColor: IOSTheme.secondaryBackground,

      // Text
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: IOSTheme.textTheme,

      // Color Scheme for M3 widgets
      colorScheme: const ColorScheme.dark(
        primary: IOSTheme.systemBlue,
        secondary: IOSTheme.systemBlue,
        surface: IOSTheme.secondaryBackground,
        error: IOSTheme.systemRed,
        onSurface: IOSTheme.label,
      ),

      // Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
