import 'package:flutter/material.dart';

/// Central color system for ARISE OS v2.
///
/// Keep this file focused on raw color definitions so it can be safely
/// referenced from both widgets and theming code.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFF02030A);
  static const Color surface = Color(0xFF050716);
  static const Color surfaceElevated = Color(0xFF090B1F);

  // Primary holographic accents (blue ↔ violet)
  static const Color primaryBlue = Color(0xFF00E5FF);
  static const Color primaryViolet = Color(0xFF8A4FFF);

  // Supporting accents
  static const Color success = Color(0xFF4CE0B3);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF4B81);

  // Text
  static const Color textPrimary = Color(0xFFE6ECFF);
  static const Color textSecondary = Color(0xFF9FA7CC);
  static const Color textDisabled = Color(0xFF5B617A);

  // Borders and outlines
  static const Color borderSoft = Color(0xFF1B2340);
  static const Color borderStrong = Color(0xFF1F91FF);

  // Utility
  static const Color overlayDim = Colors.black87;
}

