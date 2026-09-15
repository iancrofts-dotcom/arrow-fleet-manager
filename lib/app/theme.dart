import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppConstants.arrowBlue,
          secondary: AppConstants.brandNavy,
          surface: AppConstants.surfaceColor,
          error: AppConstants.dangerColor,
        );
    final typography = Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppConstants.appBackgroundColor,
      dividerTheme: const DividerThemeData(
        color: AppConstants.borderColor,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textTheme: typography.copyWith(
        headlineMedium: typography.headlineMedium?.copyWith(
          color: AppConstants.primaryTextColor,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: typography.headlineSmall?.copyWith(
          color: AppConstants.primaryTextColor,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: typography.titleLarge?.copyWith(
          color: AppConstants.primaryTextColor,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: typography.titleMedium?.copyWith(
          color: AppConstants.primaryTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: typography.bodyMedium?.copyWith(
          color: AppConstants.primaryTextColor,
        ),
        bodySmall: typography.bodySmall?.copyWith(
          color: AppConstants.secondaryTextColor,
        ),
        labelLarge: typography.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.spaceSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.spaceSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.spaceSm),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMd,
            vertical: AppConstants.spaceSm,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMd,
            vertical: AppConstants.spaceSm,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppConstants.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
        ),
      ),
    );
  }
}
