import 'package:flutter/material.dart';

class Palette {
  // Backgrounds
  static const Color backgroundDeep = Color(0xFF000000);
  static const Color backgroundSoft = Color(0xFF0F0F12);

  // Mesh Gradients (Modern Auroras)
  static const List<Color> meshGradient1 = [
    Color(0xFF0F0F12), // Deep Space
    Color(0xFF1A1A2E), // Midnight Blue
    Color(0xFF16213E), // Navy
    Color(0xFF0D0D0F), // Near Black
  ];

  static const List<Color> meshGradient2 = [
    Color(0xFF2E2E3A), // Dark Slate
    Color(0xFF252530), // Gunmetal
    Color(0xFF101014), // Almost Black
  ];

  // Neon Accents
  static const Color neonBlue = Color(0xFF2997FF);
  static const Color neonPurple = Color(0xFFBF5AF2);
  static const Color neonPink = Color(0xFFFF2D55);
  static const Color neonCyan = Color(0xFF32ADE6);
  static const Color neonGreen = Color(0xFF30D158);

  // Glass Surfaces
  static const Color glassWhite = Color(0x1AFFFFFF); // 10%
  static const Color glassWhiteHover = Color(0x26FFFFFF); // 15%
  static const Color glassBlack = Color(0x80000000); // 50%

  // Text & Icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFEBEBF5); // ~60%
  static const Color textTertiary = Color(0x99EBEBF5); // ~60% on Secondary
  static const Color textQuaternary = Color(0x4DEBEBF5); // ~30%

  // Functional
  static const Color success = Color(0xFF30D158);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFFD60A);

  // Borders
  static const Color borderWhite = Color(0x1FFFFFFF); // 12%
}
