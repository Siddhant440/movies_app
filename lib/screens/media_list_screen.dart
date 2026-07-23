import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/data/media_category.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/providers/media_providers.dart';
import 'package:movieApp/providers/saved_movie_providers.dart';
import 'package:movieApp/screens/details_screen.dart';
import 'package:movieApp/screens/matches_page.dart'; // ← Added
import 'package:movieApp/screens/widgets/top_pick_badge.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class MediaListScreen extends ConsumerStatefulWidget {
  final MediaCategory category;
  final AppUser? user;

  const MediaListScreen({super.key, required this.category, this.user});

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final state = ref.read(paginatedMediaProvider(widget.category));
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !state.isLoading &&
          state.hasMore) {
        ref
            .read(paginatedMediaProvider(widget.category).notifier)
            .fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedMediaProvider(widget.category));
    final savedIds = widget.user == null
        ? null
        : ref.watch(savedMovieIdsProvider(widget.user!.localId));

    final isInitialLoad = state.items.isEmpty && state.isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.category.label, style: AppFonts.title(context)),
        actions: [
          // Matches icon button (same as UsersPage)
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: AppColors.textPrimary,
              size: h(context) * 0.028,
            ),
            tooltip: 'View Matches',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchesPage()),
              );
            },
          ),
        ],
      ),
      body: isInitialLoad
          ? const MediaGridSkeleton()
          : GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(w(context) * 0.02),
              itemCount: state.items.length + (state.isLoading ? 2 : 0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: h(context) * 0.01,
                crossAxisSpacing: w(context) * 0.02,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const MovieCardSkeleton();
                }
                final item = state.items[index];
                final isSaved =
                    savedIds?.maybeWhen(
                      data: (ids) => ids.contains(item.id),
                      orElse: () => false,
                    ) ??
                    false;
                final isTopPick = ref
                    .watch(isTopPickProvider(item.id))
                    .maybeWhen(data: (v) => v, orElse: () => false);

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailsScreen(model: item, user: widget.user),
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
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    '${ApiConstants.imageBaseUrl}/w500${item.posterPath}',
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
                          SizedBox(height: h(context) * 0.01),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.cardTitle(context),
                          ),
                        ],
                      ),
                      if (isTopPick)
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: TopPickCornerBadge(),
                        ),
                      if (widget.user != null)
                        Positioned(
                          top: h(context) * 0.008,
                          right: w(context) * 0.016,
                          child: IconButton(
                            onPressed: () async {
                              final notifier = ref.read(
                                savedMoviesProvider(
                                  widget.user!.localId,
                                ).notifier,
                              );

                              if (isSaved) {
                                await notifier.removeMovie(item.id);
                              } else {
                                final messenger = ScaffoldMessenger.of(context);
                                final saved = await notifier.saveMovie(item);
                                if (saved && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Movie saved to profile',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withAlpha(50),
                              minimumSize: const Size(10, 10),
                            ),
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.white,
                              size: h(context) * 0.022,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
