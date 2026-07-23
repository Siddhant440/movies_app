// import 'package:flutter/material.dart';
// import 'package:movieApp/theme/app_colors.dart';

// /// Base shimmer sweep effect - wraps any child (typically a solid-color
// /// skeleton shape) with an animated light band that sweeps across it,
// /// left to right, on a loop. Used everywhere in place of
// /// CircularProgressIndicator so all loading states read as
// /// shimmer/skeleton placeholders instead of spinners.
// class ShimmerEffect extends StatefulWidget {
//   final Widget child;
//   const ShimmerEffect({super.key, required this.child});

//   @override
//   State<ShimmerEffect> createState() => _ShimmerEffectState();
// }

// class _ShimmerEffectState extends State<ShimmerEffect>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return ShaderMask(
//           blendMode: BlendMode.srcATop,
//           shaderCallback: (bounds) {
//             final dx = _controller.value;
//             return LinearGradient(
//               begin: Alignment(-1.5 + dx * 3, 0),
//               end: Alignment(0.0 + dx * 3, 0),
//               colors: [
//                 AppColors.shimmerBase,
//                 AppColors.shimmerHighlight,
//                 AppColors.shimmerBase,
//               ],
//               stops: const [0.35, 0.5, 0.65],
//             ).createShader(bounds);
//           },
//           child: child,
//         );
//       },
//       child: widget.child,
//     );
//   }
// }

// /// Rectangular skeleton block (posters, text lines, tiles, etc).
// class ShimmerBox extends StatelessWidget {
//   final double? width;
//   final double? height;
//   final BorderRadius borderRadius;

//   const ShimmerBox({
//     super.key,
//     this.width,
//     this.height,
//     this.borderRadius = const BorderRadius.all(Radius.circular(8)),
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ShimmerEffect(
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: AppColors.shimmerBase,
//           borderRadius: borderRadius,
//         ),
//       ),
//     );
//   }
// }

// /// Circular skeleton block (avatars).
// class ShimmerCircle extends StatelessWidget {
//   final double size;
//   const ShimmerCircle({super.key, required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return ShimmerEffect(
//       child: Container(
//         width: size,
//         height: size,
//         decoration: const BoxDecoration(
//           color: AppColors.surfaceAlt,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }

// /// Poster + title skeleton matching the grid cards used across
// /// Movies/TV/Saved Movies screens.
// class MovieCardSkeleton extends StatelessWidget {
//   const MovieCardSkeleton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Expanded(
//           child: ShimmerBox(
//             width: double.infinity,
//             borderRadius: BorderRadius.all(Radius.circular(10)),
//           ),
//         ),
//         const SizedBox(height: 10),
//         ShimmerBox(
//           width: 70,
//           height: 10,
//           borderRadius: BorderRadius.circular(4),
//         ),
//       ],
//     );
//   }
// }

// /// Full poster grid skeleton - used while the first page of a media list
// /// (or saved movies list) is still loading, instead of a spinner.
// class MediaGridSkeleton extends StatelessWidget {
//   final int itemCount;
//   const MediaGridSkeleton({super.key, this.itemCount = 8});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(10),
//       child: GridView.builder(
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: itemCount,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 10,
//           crossAxisSpacing: 10,
//           childAspectRatio: 0.6,
//         ),
//         itemBuilder: (context, index) => const MovieCardSkeleton(),
//       ),
//     );
//   }
// }

// /// Single skeleton user tile - mirrors the layout of `_UserTile` on the
// /// Users page (avatar + two text lines).
// class UserTileSkeleton extends StatelessWidget {
//   const UserTileSkeleton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         child: Row(
//           children: [
//             const ShimmerCircle(size: 60),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ShimmerBox(
//                     width: 160,
//                     height: 18,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   const SizedBox(height: 10),
//                   ShimmerBox(
//                     width: 100,
//                     height: 12,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Scrollable list of [UserTileSkeleton] - used both for the initial
// /// Users page load and for the "load more" footer while paginating.
// class UsersListSkeleton extends StatelessWidget {
//   final int itemCount;
//   final ScrollController? controller;
//   final EdgeInsetsGeometry padding;

//   const UsersListSkeleton({
//     super.key,
//     this.itemCount = 8,
//     this.controller,
//     this.padding = const EdgeInsets.all(16),
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       controller: controller,
//       padding: padding,
//       physics: controller == null ? const NeverScrollableScrollPhysics() : null,
//       shrinkWrap: controller == null,
//       itemCount: itemCount,
//       itemBuilder: (context, index) => const UserTileSkeleton(),
//     );
//   }
// }

// /// Skeleton for a single row on the Matches page.
// class MatchTileSkeleton extends StatelessWidget {
//   const MatchTileSkeleton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           ShimmerBox(
//             width: 48,
//             height: 72,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ShimmerBox(
//                   width: double.infinity,
//                   height: 14,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 const SizedBox(height: 8),
//                 ShimmerBox(
//                   width: 120,
//                   height: 12,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Full skeleton list for the Matches page's initial load.
// class MatchesListSkeleton extends StatelessWidget {
//   final int itemCount;
//   const MatchesListSkeleton({super.key, this.itemCount = 6});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       itemCount: itemCount,
//       itemBuilder: (context, index) => const MatchTileSkeleton(),
//     );
//   }
// }

// /// Non-circular, non-spinner "busy" indicator for inline contexts like
// /// buttons (e.g. the Save button on Add Profile) - three pulsing bars
// /// instead of a CircularProgressIndicator.
// class PulsingDotsIndicator extends StatefulWidget {
//   final Color color;
//   const PulsingDotsIndicator({super.key, this.color = Colors.black});

//   @override
//   State<PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
// }

// class _PulsingDotsIndicatorState extends State<PulsingDotsIndicator>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, _) {
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: List.generate(3, (i) {
//             final t = (_controller.value - (i * 0.2)) % 1.0;
//             final scale = 0.4 + 0.6 * (0.5 - (t - 0.5).abs()) * 2;
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 2),
//               child: Transform.scale(
//                 scale: scale.clamp(0.4, 1.0),
//                 child: Container(
//                   width: 7,
//                   height: 7,
//                   decoration: BoxDecoration(
//                     color: widget.color,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/utils/responsive.dart';

/// Base shimmer sweep effect - wraps any child (typically a solid-color
/// skeleton shape) with an animated light band that sweeps across it,
/// left to right, on a loop. Used everywhere in place of
/// CircularProgressIndicator so all loading states read as
/// shimmer/skeleton placeholders instead of spinners.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.5 + dx * 3, 0),
              end: Alignment(0.0 + dx * 3, 0),
              colors: [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Rectangular skeleton block (posters, text lines, tiles, etc).
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Circular skeleton block (avatars).
class ShimmerCircle extends StatelessWidget {
  final double size;
  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Poster + title skeleton matching the grid cards used across
/// Movies/TV/Saved Movies screens.
class MovieCardSkeleton extends StatelessWidget {
  const MovieCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: ShimmerBox(
            width: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        SizedBox(height: h(context) * 0.01), // 10px
        ShimmerBox(
          width: w(context) * 0.14, // 70px
          height: h(context) * 0.01, // 10px
          borderRadius: BorderRadius.circular(w(context) * 0.008), // 4px
        ),
      ],
    );
  }
}

/// Full poster grid skeleton - used while the first page of a media list
/// (or saved movies list) is still loading, instead of a spinner.
class MediaGridSkeleton extends StatelessWidget {
  final int itemCount;
  const MediaGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(w(context) * 0.02), // 10px
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: h(context) * 0.01, // 10px
          crossAxisSpacing: w(context) * 0.02, // 10px
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) => const MovieCardSkeleton(),
      ),
    );
  }
}

/// Single skeleton user tile - mirrors the layout of `_UserTile` on the
/// Users page (avatar + two text lines).
/// Single skeleton user tile - mirrors the layout of `_UserTile`
class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: h(context) * 0.012),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(w(context) * 0.032),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w(context) * 0.04,
          vertical: h(context) * 0.012,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar - exact match
            ShimmerCircle(size: h(context) * 0.06),

            SizedBox(width: w(context) * 0.032),

            // Content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (matches emphasis font height)
                  ShimmerBox(
                    width: w(context) * 0.48,
                    height: h(context) * 0.028, // Slightly refined
                    borderRadius: BorderRadius.circular(w(context) * 0.008),
                  ),
                  SizedBox(height: h(context) * 0.008),

                  // First subtitle line
                  ShimmerBox(
                    width: w(context) * 0.65,
                    height: h(context) * 0.014,
                    borderRadius: BorderRadius.circular(w(context) * 0.008),
                  ),
                  SizedBox(height: h(context) * 0.004),

                  // Second subtitle line
                  ShimmerBox(
                    width: w(context) * 0.42,
                    height: h(context) * 0.014,
                    borderRadius: BorderRadius.circular(w(context) * 0.008),
                  ),
                ],
              ),
            ),

            // Trailing area - better match for the real trailing (cloud/sync + more button)
            SizedBox(
              width: h(context) * 0.085, // Increased to accommodate both icons
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Small shimmer for the cloud/sync icon
                  ShimmerBox(
                    width: h(context) * 0.022,
                    height: h(context) * 0.022,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  // Shimmer for the more_horiz button
                  ShimmerBox(
                    width: h(context) * 0.028,
                    height: h(context) * 0.028,
                    borderRadius: BorderRadius.circular(w(context) * 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list of [UserTileSkeleton] - used both for the initial
/// Users page load and for the "load more" footer while paginating.
class UsersListSkeleton extends StatelessWidget {
  final int itemCount;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;

  const UsersListSkeleton({
    super.key,
    this.itemCount = 8,
    this.controller,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: controller == null ? const NeverScrollableScrollPhysics() : null,
      shrinkWrap: controller == null,
      itemCount: itemCount,
      itemBuilder: (context, index) => const UserTileSkeleton(),
    );
  }
}

/// Skeleton for a single row on the Matches page.
class MatchTileSkeleton extends StatelessWidget {
  const MatchTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: w(context) * 0.032, // 16px
        vertical: h(context) * 0.006, // 6px
      ),
      padding: EdgeInsets.all(w(context) * 0.02), // 10px
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(w(context) * 0.032), // 16px
      ),
      child: Row(
        children: [
          ShimmerBox(
            width: w(context) * 0.096, // 48px
            height: h(context) * 0.072, // 72px
            borderRadius: BorderRadius.circular(w(context) * 0.02), // 10px
          ),
          SizedBox(width: w(context) * 0.028), // 14px
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: h(context) * 0.014, // 14px
                  borderRadius: BorderRadius.circular(w(context) * 0.008),
                ),
                SizedBox(height: h(context) * 0.008),
                ShimmerBox(
                  width: w(context) * 0.24, // 120px
                  height: h(context) * 0.012, // 12px
                  borderRadius: BorderRadius.circular(w(context) * 0.008),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full skeleton list for the Matches page's initial load.
class MatchesListSkeleton extends StatelessWidget {
  final int itemCount;
  const MatchesListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: h(context) * 0.008), // 8px
      itemCount: itemCount,
      itemBuilder: (context, index) => const MatchTileSkeleton(),
    );
  }
}

/// Non-circular, non-spinner "busy" indicator for inline contexts like
/// buttons (e.g. the Save button on Add Profile) - three pulsing bars
/// instead of a CircularProgressIndicator.
class PulsingDotsIndicator extends StatefulWidget {
  final Color color;
  const PulsingDotsIndicator({super.key, this.color = Colors.black});

  @override
  State<PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
}

class _PulsingDotsIndicatorState extends State<PulsingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final scale = 0.4 + 0.6 * (0.5 - (t - 0.5).abs()) * 2;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w(context) * 0.004,
              ), // 2px
              child: Transform.scale(
                scale: scale.clamp(0.4, 1.0),
                child: Container(
                  width: w(context) * 0.014, // 7px
                  height: w(context) * 0.014,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(
                      w(context) * 0.004,
                    ), // 2px
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
