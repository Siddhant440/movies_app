
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/models/saved_movie_model.dart';
import 'package:movieApp/providers/saved_movie_providers.dart';
import 'package:movieApp/screens/details_screen.dart';
import 'package:movieApp/screens/widgets/top_pick_badge.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class SavedMoviesScreen extends ConsumerWidget {
  final AppUser user;
  const SavedMoviesScreen({super.key, required this.user});

  Future<bool> _confirmUnsave(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w(context) * 0.032), // ~16px
        ),
        title: Text(
          'Remove from saved?',
          style: AppFonts.emphasis(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove "$title" from ${user.fullName}\'s saved movies.',
          style: AppFonts.caption(context).copyWith(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppFonts.caption(
                context,
              ).copyWith(color: AppColors.textFaint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Remove',
              style: AppFonts.caption(context).copyWith(
                color: AppColors.destructive,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedMoviesProvider(user.localId));
    final movies = state.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Saved Movies',
          style: AppFonts.title(context), // Already responsive
        ),
      ),
      body: movies.isEmpty && state.isLoading
          ? const MediaGridSkeleton()
          : movies.isEmpty
          ? Center(
              child: Text(
                'No saved movies yet. Browse and explore.',
                style: AppFonts.caption(
                  context,
                ).copyWith(color: AppColors.textMuted),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(w(context) * 0.02), // ~10px
              child: GridView.builder(
                itemCount: movies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: h(context) * 0.01, // ~10px
                  crossAxisSpacing: w(context) * 0.02, // ~10px
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  final saved = movies[index];
                  final adapter = SavedMovieDetails(saved);
                  final isTopPick = ref
                      .watch(isTopPickProvider(saved.movieId))
                      .maybeWhen(data: (v) => v, orElse: () => false);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(
                          model: adapter,
                          user: user,
                          requireUnsaveConfirmation: true,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  w(context) * 0.02,
                                ), // ~10px
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
                            SizedBox(height: h(context) * 0.008), // ~8px
                            Text(
                              saved.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.cardTitle(context),
                            ),
                          ],
                        ),
                        if (isTopPick)
                          Positioned(
                            top: h(context) * 0.008, // ~8px
                            left: w(context) * 0.016, // ~8px
                            child: const TopPickCornerBadge(),
                          ),
                        Positioned(
                          top: h(context) * 0.008,
                          right: w(context) * 0.016,
                          child: IconButton(
                            onPressed: () async {
                              final confirmed = await _confirmUnsave(
                                context,
                                saved.title,
                              );
                              if (!confirmed) return;
                              await ref
                                  .read(
                                    savedMoviesProvider(user.localId).notifier,
                                  )
                                  .removeMovie(saved.movieId);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withAlpha(50),
                              minimumSize: const Size(10, 10),
                            ),
                            icon: Icon(
                              Icons.bookmark,
                              color: AppColors.textPrimary,
                              size: h(context) * 0.022, // ~22px
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
