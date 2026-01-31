import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  const AppTypography._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  // Headings
  static TextStyle get h1 =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle get h2 =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get h3 =>
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get body =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.normal);
  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static TextStyle get caption => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Labels (Buttons, Badges)
  static TextStyle get label =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle get mono =>
      GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textSecondary);
}
