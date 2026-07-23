import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/models/saved_movie_model.dart';
import 'package:movieApp/providers/saved_movie_providers.dart';
import 'package:movieApp/screens/details_screen.dart'; // Assuming this path
import 'package:movieApp/screens/widgets/top_pick_badge.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesWithTopPickProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Matches', style: AppFonts.title(context)),
      ),
      body: matchesAsync.when(
        loading: () => const MatchesListSkeleton(),
        error: (err, _) => Center(
          child: Text(
            'Failed to load matches: $err',
            style: AppFonts.caption(context).copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const _EmptyMatchesState();
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: h(context) * 0.008),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _MatchTile(
                match: match,
              );
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends ConsumerWidget {
  final MovieMatch match;

  const _MatchTile({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchersAsync = ref.watch(movieWatchersProvider(match.movieId));

    String getYear() {
      if (match.releaseDate.isEmpty || match.releaseDate.length < 4) return '';
      return match.releaseDate.substring(0, 4);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              model: SavedMovieDetails(
                SavedMovie(
                  localId: '',
                  userLocalId: '',
                  movieId: match.movieId,
                  title: match.title,
                  posterPath: match.posterPath,
                  overview: match.overview,
                  releaseDate: match.releaseDate,
                  voteAverage: match.voteAverage,
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: w(context) * 0.032,
          vertical: h(context) * 0.008,
        ),
        padding: EdgeInsets.all(w(context) * 0.035),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(w(context) * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(w(context) * 0.03),
              child: match.posterPath.isEmpty
                  ? Container(
                      width: w(context) * 0.22,
                      height: h(context) * 0.14,
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.grey, size: 36),
                    )
                  : Image.network(
                      '${ApiConstants.imageBaseUrl}/w185${match.posterPath}',
                      width: w(context) * 0.22,
                      height: h(context) * 0.14,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return ShimmerBox(
                          width: w(context) * 0.22,
                          height: h(context) * 0.14,
                          borderRadius: BorderRadius.circular(w(context) * 0.03),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: w(context) * 0.22,
                        height: h(context) * 0.14,
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
                      ),
                    ),
            ),
            SizedBox(width: w(context) * 0.04),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.isTopPick)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: TopPickBadge(),
                    ),

                  Text(
                    match.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.emphasis(context).copyWith(
                      fontSize: h(context) * 0.022,
                    ),
                  ),

                  // Release Year
                  if (getYear().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: h(context) * 0.002),
                      child: Text(
                        getYear(),
                        style: AppFonts.caption(context).copyWith(
                          fontSize: h(context) * 0.0155,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),

                  SizedBox(height: h(context) * 0.008),

                  // Avatars + Count
                  watchersAsync.when(
                    data: (watchers) {
                      final displayCount = watchers.length.clamp(0, 3);
                      final visible = watchers.take(displayCount).toList();

                      return Row(
                        children: [
                          if (visible.isNotEmpty)
                            _AvatarStack(users: visible),
                          SizedBox(width: w(context) * 0.02),
                          Expanded(
                            child: Text(
                              '${match.totalUsers} user${match.totalUsers == 1 ? '' : 's'} saved this',
                              style: AppFonts.caption(context).copyWith(
                                fontSize: h(context) * 0.0165,
                                color: match.isTopPick
                                    ? AppColors.topPickGold
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Text(
                      '${match.totalUsers} users saved this',
                      style: AppFonts.caption(context).copyWith(
                        fontSize: h(context) * 0.0165,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    error: (_, __) => Text(
                      '${match.totalUsers} users saved this',
                      style: AppFonts.caption(context).copyWith(
                        fontSize: h(context) * 0.0165,
                        color: AppColors.textSecondary,
                      ),
                    ),
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

class _AvatarStack extends StatelessWidget {
  final List<AppUser> users;
  const _AvatarStack({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < users.length; i++) ...[
          if (i != 0) const SizedBox(width: 1),
          _Avatar(user: users[i]),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser user;
  const _Avatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final size = h(context) * 0.022;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary,
        border: Border.all(color: Colors.black, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: user.avatar.isNotEmpty
          ? Image.network(
              user.avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.black,
              ),
            )
          : Icon(Icons.person, size: size * 0.6, color: Colors.black),
    );
  }
}

class _EmptyMatchesState extends StatelessWidget {
  const _EmptyMatchesState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(w(context) * 0.064),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: h(context) * 0.056,
              color: Colors.grey[600],
            ),
            SizedBox(height: h(context) * 0.02),
            Text(
              'No matches yet',
              style: AppFonts.title(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: h(context) * 0.01),
            Text(
              'A match shows up here as soon as the same movie is saved '
              'by people.',
              style: AppFonts.caption(context).copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton for loading (add if not present elsewhere)
class MatchesListSkeleton extends StatelessWidget {
  const MatchesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: h(context) * 0.008),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: w(context) * 0.032,
            vertical: h(context) * 0.006,
          ),
          padding: EdgeInsets.all(w(context) * 0.02),
          child: Row(
            children: [
              ShimmerBox(
                width: w(context) * 0.096,
                height: h(context) * 0.072,
                borderRadius: BorderRadius.circular(w(context) * 0.02),
              ),
              SizedBox(width: w(context) * 0.028),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: double.infinity,
                      height: h(context) * 0.018,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: h(context) * 0.008),
                    ShimmerBox(
                      width: w(context) * 0.4,
                      height: h(context) * 0.014,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}