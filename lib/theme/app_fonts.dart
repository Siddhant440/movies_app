import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/utils/responsive.dart';

/// Typography system for the app (responsive + increased sizes).
class AppFonts {
  AppFonts._();

  /// Big screen headlines
  static TextStyle display(BuildContext context) => GoogleFonts.montserrat(
        fontSize: h(context) * 0.030, // 30
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  /// Section / app-bar / card-group titles
  static TextStyle title(BuildContext context) => GoogleFonts.montserrat(
        fontSize: h(context) * 0.022, // 22
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  /// Primary UI copy - buttons, list items, labels
  static TextStyle emphasis(BuildContext context) => GoogleFonts.montserrat(
        fontSize: h(context) * 0.018, // 18
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Long-form readable copy (movie overview)
  static TextStyle body(BuildContext context) => GoogleFonts.lato(
        fontSize: h(context) * 0.018, // 18
        height: 1.5,
        color: AppColors.textBody,
      );

  /// Secondary / meta text - subtitles, hints, captions, badges
  static TextStyle caption(BuildContext context) => GoogleFonts.montserrat(
        fontSize: h(context) * 0.015, // 15
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ---- Common derived variants ----
  static TextStyle button(BuildContext context) =>
      emphasis(context).copyWith(
        fontSize: h(context) * 0.0175, // 17.5
        color: AppColors.background,
      );

  static TextStyle cardTitle(BuildContext context) =>
      caption(context).copyWith(
        fontSize: h(context) * 0.014, // 14
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle badge(BuildContext context) =>
      caption(context).copyWith(
        fontSize: h(context) * 0.0145, // 14.5
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: AppColors.topPickGold,
      );

  static TextStyle fieldLabel(BuildContext context) =>
      caption(context).copyWith(
        fontSize: h(context) * 0.016, // 16
        fontWeight: FontWeight.w600,
      );
}