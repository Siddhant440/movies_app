import 'package:flutter/material.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';

/// Application theme configuration (dark theme).
///
/// Updated to support the new responsive `AppFonts` that depend on screen height.
class AppTheme {
  AppTheme._();

  /// Returns a responsive dark theme based on current screen size.
  static ThemeData dark(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: AppFonts.title(context),
        centerTitle: false,
      ),
      textTheme: TextTheme(
        headlineMedium: AppFonts.display(context),
        titleLarge: AppFonts.title(context),
        bodyLarge: AppFonts.emphasis(context),
        bodyMedium: AppFonts.body(context),
        bodySmall: AppFonts.caption(context),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        secondary: AppColors.secondary,
      ),
      useMaterial3: true,
    );
  }
}