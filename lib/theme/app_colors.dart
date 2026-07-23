import 'package:flutter/material.dart';

/// Centralized palette, extracted from the colors already used throughout
/// the app (backgrounds, accents, status colors). Use these instead of
/// hardcoding Colors.xxx / Color(0xFF...) in screens/widgets.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF212121); // grey[900]-ish tiles/dialogs
  static const Color surfaceAlt = Color(0xFF303030); // grey[850] shimmer base

  // Brand accents
  static const Color primary = Color(0xFF800000); // maroon - avatars, FAB
  static const Color secondary = Color(0xFF303030); // spring green - "See all", avatar ring
  static const Color topPickGold = Color(0xFFFFD700); // top pick badge/star

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFBDBDBD); // grey[400]
  static const Color textMuted = Color(0xFF9E9E9E); // grey[500]
  static const Color textFaint = Color(0xFF757575); // grey[600]
  static const Color textBody = Color(0xFFE0E0E0); // grey[300]

  // Status
  static const Color pendingSync = Colors.orangeAccent;
  static const Color destructive = Colors.redAccent;

  // Shimmer
  static const Color shimmerBase = Color(0xFF424242); // grey[850]
  static const Color shimmerHighlight = Color(0xFF757575); // grey[600]
}
