import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF12355B);
  static const blue = Color(0xFF1769E0);
  static const sky = Color(0xFF37A2FF);
  static const lightBlue = Color(0xFFEAF3FF);
  static const canvas = Color(0xFFF5F8FC);
  static const text = Color(0xFF182230);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE7ECF3);
  static const success = Color(0xFF10A874);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const purple = Color(0xFF7B61D1);
  static const teal = Color(0xFF0891B2);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 28;
}

abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 22;
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: AppColors.text,
          fontSize: 24,
          height: 1.22,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontSize: 17,
          height: 1.3,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFD9E0EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFD9E0EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: Color(0xFFBFD7FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightBlue,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
