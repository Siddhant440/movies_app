
import 'package:flutter/material.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';

/// Inline "TOP PICK" pill - used above the watchers line on the Details
/// screen and in the Matches list.
class TopPickBadge extends StatelessWidget {
  const TopPickBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w(context) * 0.01,
        vertical: h(context) * 0.002,
      ),
      decoration: BoxDecoration(
        color: AppColors.topPickGold.withAlpha(30),
        borderRadius: BorderRadius.circular(w(context) * 0.012),
        border: Border.all(color: AppColors.topPickGold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: h(context) * 0.014,
            color: AppColors.topPickGold,
          ),
          SizedBox(width: w(context) * 0.008),
          Text(
            'TOP PICK',
            style: AppFonts.badge(context),   // ← Updated
          ),
        ],
      ),
    );
  }
}

/// Small corner ribbon for grid/movie cards (Movies list, Saved Movies list).
class TopPickCornerBadge extends StatelessWidget {
  const TopPickCornerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w(context) * 0.012,
        vertical: h(context) * 0.003,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(w(context) * 0.012),
        border: Border.all(color: AppColors.topPickGold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: h(context) * 0.011,
            color: AppColors.topPickGold,
          ),
          SizedBox(width: w(context) * 0.004),
          Text(
            'TOP PICK',
            style: AppFonts.badge(context).copyWith(   // ← Updated
              fontSize: h(context) * 0.0095,           // ~9.5px (responsive)
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}