import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/models/saved_movie_model.dart';
import 'package:movieApp/providers/saved_movie_providers.dart';
import 'package:movieApp/screens/details_screen.dart';
import 'package:movieApp/screens/user/saved_movies_screen.dart';
import 'package:movieApp/screens/widgets/top_pick_badge.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

/// Read-only profile screen for one user - same visual language as
/// AddUserPage (avatar circle, name, sub-text), plus a preview row of up
/// to 5 saved movies with a "See all" link to [SavedMoviesScreen].
class UserDetailsScreen extends ConsumerWidget {
  final AppUser user;
  const UserDetailsScreen({super.key, required this.user});

  static const int _previewCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedMoviesProvider(user.localId));
    final movies = state.items;
    final preview = movies.take(_previewCount).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Profile', style: AppFonts.title(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: w(context) * 0.048,
          vertical: h(context) * 0.02,
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: w(context) * 0.22,
                height: h(context) * 0.11,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: user.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.avatar,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            ShimmerCircle(size: h(context) * 0.11),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: h(context) * 0.058,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: h(context) * 0.058,
                        color: AppColors.textPrimary,
                      ),
              ),
            ),
            SizedBox(height: h(context) * 0.024),
            Text(
              user.fullName,
              style: AppFonts.display(context), // Removed manual copyWith
              textAlign: TextAlign.center,
            ),
            SizedBox(height: h(context) * 0.006),
            Text(
              user.movieTaste,
              style: AppFonts.caption(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: h(context) * 0.04),
            Row(
              children: [
                Text('Saved Movies', style: AppFonts.title(context)),
                const Spacer(),
                if (movies.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedMoviesScreen(user: user),
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: AppFonts.emphasis(
                        context,
                      ).copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            SizedBox(height: h(context) * 0.012),
            if (movies.isEmpty && state.isLoading)
              SizedBox(
                height: h(context) * 0.25,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: w(context) * 0.024),
                  itemBuilder: (context, index) => SizedBox(
                    width: w(context) * 0.28,
                    child: const MovieCardSkeleton(),
                  ),
                ),
              )
            else if (movies.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: h(context) * 0.02),
                child: Text(
                  'No saved movies yet. Browse and explore.',
                  style: AppFonts.caption(context),
                ),
              )
            else
              SizedBox(
                height: h(context) * 0.25,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: w(context) * 0.024),
                  itemBuilder: (context, index) {
                    final saved = preview[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(
                            model: SavedMovieDetails(saved),
                            user: user,
                            requireUnsaveConfirmation: true,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: w(context) * 0.28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        w(context) * 0.02,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '${ApiConstants.imageBaseUrl}/w500${saved.posterPath}',
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => ShimmerBox(
                                          width: double.infinity,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(w(context) * 0.02),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (ref
                                      .watch(isTopPickProvider(saved.movieId))
                                      .maybeWhen(
                                        data: (v) => v,
                                        orElse: () => false,
                                      ))
                                    const Positioned(
                                      top: 6,
                                      left: 6,
                                      child: TopPickCornerBadge(),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: h(context) * 0.006),
                            Text(
                              saved.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.cardTitle(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
