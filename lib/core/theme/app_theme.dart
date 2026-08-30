import 'package:flutter/material.dart';

// Palette stricte de l'application : blanc, noir et vert ENI.

class AppColors {
  AppColors._();

  // Couleurs issues de Design.html
  static const primary = Color(0xFF00C853);
  static const primaryDark = Color(0xFF006E2A);
  static const primaryLight = Color(0xFFE8F8ED);

  static const bgLight = Color(0xFFF9F9F9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF000000);

  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF444748);
  static const textMuted = Color(0xFF747878);

  static const bubbleReceived = Color(0xFFFFFFFF);
  static const success = primary;
  static const warning = primary;
  static const danger = Color(0xFFBA1A1A);

  static const unreadBadge = primary;
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
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF3F3F3),
        surfaceContainer: Color(0xFFEEEEEE),
        surfaceContainerHigh: Color(0xFFE8E8E8),
        surfaceContainerHighest: Color(0xFFE2E2E2),
        outline: Color(0xFF747878),
        outlineVariant: Color(0xFFC4C7C8),
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE2E2E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE2E2E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: Color(0xFF747878)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        outline: Colors.white,
        error: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: AppColors.primary,
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(color: Colors.white),
        ),
        iconTheme: MaterialStatePropertyAll(IconThemeData(color: Colors.white)),
      ),
    );
  }
}
