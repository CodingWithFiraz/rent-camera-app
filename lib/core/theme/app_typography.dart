import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Hierarki teks aplikasi.
///
/// Hanya memakai beberapa tingkat (headline, title, body, label) sesuai
/// blueprint §11 agar tidak ada ukuran font acak di widget.
abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
}
