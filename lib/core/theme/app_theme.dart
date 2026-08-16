import 'package:flutter/material.dart';

// Design tokens issus du prompt de design  sur les 5 écrans.

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1D5FA5); // bleu universitaire
  static const primaryLight = Color(0xFFE8F0FB);

  static const bgLight = Color(0xFFF5F5F5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textMuted = Color(0xFF9A9A9A);

  static const bubbleReceived = Color(0xFFF0F0F0);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB26A00);
  static const danger = Color(0xFFC62828);

  static const unreadBadge = Color(0xFFE53935);
}

class AppTheme {
  AppTheme._();

  static const double radiusM = 14;
  static const double radiusL = 20;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
