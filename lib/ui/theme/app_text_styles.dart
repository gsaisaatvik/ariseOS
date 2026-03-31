import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system tuned for a minimal, premium system HUD.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Roboto';

  /// Large headers such as NOTIFICATION / QUEST INFO.
  static const TextStyle headerLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: AppColors.textPrimary,
  );

  /// Medium section titles.
  static const TextStyle headerMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  /// Small system labels (STATUS, GOAL, WARNING).
  static const TextStyle systemLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
    color: AppColors.textSecondary,
  );

  /// Primary body copy.
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Secondary / explanatory text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Button labels.
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );
}

