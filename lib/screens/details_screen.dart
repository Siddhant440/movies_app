import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/models/details_model.dart';
import 'package:movieApp/providers/saved_movie_providers.dart';
import 'package:movieApp/screens/widgets/top_pick_badge.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  final DetailsModel model;
  final AppUser? user;
  final bool requireUnsaveConfirmation;

  const DetailsScreen({
    super.key,
    required this.model,
    this.user,
    this.requireUnsaveConfirmation = false,
  });

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  static const double _minSize = 0.42;
  static const double _maxSize = 0.95;

  static const double _minScale = 1.0;
  static const double _maxScale = 1.18;

  static const int _minAlpha = 70;
  static const int _maxAlpha = 190;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  double get _t {
    if (!_sheetController.isAttached) return 0.0;
    final size = _sheetController.size;
    return ((size - _minSize) / (_maxSize - _minSize)).clamp(0.0, 1.0);
  }

  Future<bool> _confirmUnsave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w(context) * 0.032),
        ),
        title: Text(
          'Remove from saved?',
          style: AppFonts.emphasis(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove "${widget.model.title}" from this profile\'s saved movies.',
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
  Widget build(BuildContext context) {
    final user = widget.user;
    final model = widget.model;

    final savedIds = user == null
        ? null
        : ref.watch(savedMovieIdsProvider(user.localId));
    final isSaved = savedIds?.maybeWhen(
      data: (ids) => ids.contains(model.id),
      orElse: () => false,
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, _) {
          final t = _t;
          final scale = _maxScale - (_maxScale - _minScale) * t;
          final alpha = (_minAlpha + (_maxAlpha - _minAlpha) * t).round();

          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: CachedNetworkImage(
                    imageUrl:
                        '${ApiConstants.imageBaseUrl}/original${model.posterPath}',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black87,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + h(context) * 0.012,
                left: w(context) * 0.032,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(w(context) * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: h(context) * 0.022,
                    ),
                  ),
                ),
              ),

              // Bookmark Button
              if (user != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + h(context) * 0.012,
                  right: w(context) * 0.032,
                  child: GestureDetector(
                    onTap: () async {
                      final notifier = ref.read(
                        savedMoviesProvider(user.localId).notifier,
                      );
                      if (isSaved == true) {
                        if (widget.requireUnsaveConfirmation) {
                          final confirmed = await _confirmUnsave(context);
                          if (!confirmed) return;
                        }
                        await notifier.removeMovie(model.id);
                      } else {
                        final messenger = ScaffoldMessenger.of(context);
                        final saved = await notifier.saveMovie(model);
                        if (saved && mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('Movie saved to profile'),
                              behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(w(context) * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(60),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved == true
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Colors.white,
                        size: h(context) * 0.024,
                      ),
                    ),
                  ),
                ),

              // Draggable Sheet
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _minSize,
                minChildSize: _minSize,
                maxChildSize: _maxSize,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(alpha),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(w(context) * 0.06),
                            topRight: Radius.circular(w(context) * 0.06),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: w(context) * 0.048,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: h(context) * 0.02),
                                _WatchersRow(movieId: model.id),
                                SizedBox(height: h(context) * 0.008),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AutoSizeText(
                                        model.title,
                                        maxLines: 2,
                                        style: AppFonts.display(
                                          context,
                                        ), // ← Updated
                                      ),
                                    ),
                                    SizedBox(width: w(context) * 0.032),
                                  ],
                                ),
                                SizedBox(height: h(context) * 0.005),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _extractYear(model.releaseDate),
                                      style: AppFonts.caption(context).copyWith(
                                        // ← Updated
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: w(context) * 0.02),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.yellowAccent,
                                      size: 15,
                                    ),
                                    SizedBox(width: w(context) * 0.006),
                                    Text(
                                      model.voteAverage == '0.0'
                                          ? "N/A"
                                          : double.parse(
                                              model.voteAverage,
                                            ).toStringAsFixed(1),
                                      style: AppFonts.emphasis(
                                        context,
                                      ), // ← Updated
                                    ),
                                  ],
                                ),
                                SizedBox(height: h(context) * 0.032),
                                Text(
                                  'Description',
                                  style: AppFonts.title(context), // ← Updated
                                ),
                                SizedBox(height: h(context) * 0.012),
                                Text(
                                  model.overview.isNotEmpty
                                      ? model.overview
                                      : "No description available.",
                                  style: AppFonts.body(context), // ← Updated
                                ),
                                SizedBox(height: h(context) * 0.08),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ],
          );
        },
      ),
    );
  }

  String _extractYear(String releaseDate) {
    if (releaseDate.isEmpty || releaseDate.length < 4) return '';
    try {
      return releaseDate.substring(0, 4);
    } catch (e) {
      return '';
    }
  }
}

class _WatchersRow extends ConsumerWidget {
  final int movieId;
  const _WatchersRow({required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchersAsync = ref.watch(movieWatchersProvider(movieId));
    final isTopPickAsync = ref.watch(isTopPickProvider(movieId));
    final isTopPick = isTopPickAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return watchersAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: h(context) * 0.01),
        child: ShimmerBox(
          width: w(context) * 0.32,
          height: h(context) * 0.014,
          borderRadius: BorderRadius.all(Radius.circular(w(context) * 0.008)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (watchers) {
        final count = watchers.length;
        final label = count == 0
            ? 'Be the first to save this.'
            : '$count user${count == 1 ? '' : 's'} want to watch this';

        final visibleWatchers = watchers.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTopPick)
              Padding(
                padding: EdgeInsets.only(bottom: h(context) * 0.02),
                child: const TopPickBadge(),
              ),
            Row(
              children: [
                if (visibleWatchers.isNotEmpty) ...[
                  _AvatarStack(users: visibleWatchers),
                  SizedBox(width: w(context) * 0.016),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppFonts.caption(context).copyWith(
                      // ← Updated
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<AppUser> users;
  const _AvatarStack({required this.users});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < users.length; i++) ...[
          if (i != 0) SizedBox(width: 1),
          _Avatar(user: users[i]),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final size = h(context) * 0.02;

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
          ? CachedNetworkImage(
              imageUrl: user.avatar,
              fit: BoxFit.cover,
              placeholder: (_, __) => ShimmerCircle(size: size),
              errorWidget: (_, __, ___) => Icon(
                Icons.person,
                size: h(context) * 0.012,
                color: Colors.black,
              ),
            )
          : Icon(Icons.person, size: h(context) * 0.012, color: Colors.black),
    );
  }
}
