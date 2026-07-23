import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/models/details_model.dart';
import 'package:movieApp/models/saved_movie_model.dart';
import 'package:movieApp/providers/user_providers.dart';
import 'package:movieApp/services/local_database_service.dart';

class SavedMoviesState {
  final List<SavedMovie> items;
  final bool isLoading;

  const SavedMoviesState({this.items = const [], this.isLoading = false});

  SavedMoviesState copyWith({List<SavedMovie>? items, bool? isLoading}) {
    return SavedMoviesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SavedMoviesNotifier extends StateNotifier<SavedMoviesState> {
  SavedMoviesNotifier(this.userLocalId, this._ref)
    : super(const SavedMoviesState()) {
    refresh();
  }

  final String userLocalId;
  final Ref _ref;
  final _db = LocalDatabaseService.instance;
  final _uuid = const Uuid();

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final items = await _db.getSavedMoviesForUser(userLocalId);
    state = state.copyWith(items: items, isLoading: false);
  }

  Future<bool> saveMovie(DetailsModel movie) async {
    final existing = await _db.getSavedMoviesForUser(userLocalId);
    if (existing.any((item) => item.movieId == movie.id)) {
      await refresh();
      return false;
    }

    final saved = SavedMovie(
      localId: _uuid.v4(),
      userLocalId: userLocalId,
      movieId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      overview: movie.overview,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      isSynced: false,
    );

    await _db.insertSavedMovie(saved);
    await refresh();
    // The Users page shows a saved-count, so it needs to reflect this
    // change immediately. Matches is a live Stream off the DB itself
    // (see LocalDatabaseService.watchMatches) so it updates on its own.
    await _ref.read(usersProvider.notifier).refreshFromLocal();
    // The Details screen's "N users want to watch this" row also depends
    // on saved_movies for this specific movie.
    _ref.invalidate(movieWatchersProvider(movie.id));
    return true;
  }

  Future<void> removeMovie(int movieId) async {
    await _db.removeSavedMovie(userLocalId: userLocalId, movieId: movieId);
    await refresh();
    await _ref.read(usersProvider.notifier).refreshFromLocal();
    _ref.invalidate(movieWatchersProvider(movieId));
  }
}

final savedMoviesProvider =
    StateNotifierProvider.family<SavedMoviesNotifier, SavedMoviesState, String>(
      (ref, userLocalId) {
        return SavedMoviesNotifier(userLocalId, ref);
      },
    );

final savedMovieIdsProvider = Provider.family<AsyncValue<Set<int>>, String>((
  ref,
  userLocalId,
) {
  final state = ref.watch(savedMoviesProvider(userLocalId));
  return AsyncValue.data(state.items.map((item) => item.movieId).toSet());
});

/// Cross-user shared-movie matches (Matches page). Backed by
/// [LocalDatabaseService.watchMatches], a Stream that reads entirely from
/// the local DB (no API call) and re-emits automatically whenever any
/// user's saved list changes - no manual invalidation needed.
final matchesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return LocalDatabaseService.instance.watchMatches();
});

/// The single movieId currently holding the "Top Pick" title (or null if
/// nothing is saved yet). Backed by [LocalDatabaseService.watchTopPickMovieId],
/// which always resolves to exactly one winner - the movie with the
/// highest save count right now. Every place in the app that shows a
/// top-pick badge watches this same provider, so there is only ever one
/// badge showing at a time: as soon as another movie's count passes it,
/// this value flips to the new winner and the old movie's badge disappears
/// automatically.
final topPickMovieIdProvider = StreamProvider<int?>((ref) {
  return LocalDatabaseService.instance.watchTopPickMovieId();
});

/// Which users (if any) have saved a given movie. Backed by the same
/// saved_movies + users data as everything else - no new tables. Powers
/// the "N users want to watch this" row with small avatars on the
/// Details screen. Invalidated by [SavedMoviesNotifier] whenever any
/// user saves/removes that movie, so it stays in sync automatically.
final movieWatchersProvider = FutureProvider.family<List<AppUser>, int>((
  ref,
  movieId,
) {
  return LocalDatabaseService.instance.getUsersWhoSavedMovie(movieId);
});

/// Whether [movieId] is the current sole Top Pick. True for at most one
/// movieId at a time - simply whether it matches [topPickMovieIdProvider].
final isTopPickProvider = Provider.family<AsyncValue<bool>, int>((
  ref,
  movieId,
) {
  final topPickAsync = ref.watch(topPickMovieIdProvider);
  return topPickAsync.whenData((topPickId) => topPickId == movieId);
});

/// A match row enriched with whether it's a "top pick" - the single
/// most-saved movie right now, by any mix of profiles (not necessarily
/// everyone).
class MovieMatch {
  final int movieId;
  final String title;
  final String posterPath;
  final String voteAverage;
  final String releaseDate;
  final String overview;
  final int totalUsers;
  final bool isTopPick;

  const MovieMatch({
    required this.movieId,
    required this.title,
    required this.posterPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.overview,
    required this.totalUsers,
    required this.isTopPick,
  });
}

/// Derives [MovieMatch]es (with the top-pick flag) from [matchesProvider],
/// comparing each match's movieId against [topPickMovieIdProvider].
/// Recomputes automatically whenever either the matches stream emits (a
/// save/unsave happened) or the top-pick stream emits, so the badge never
/// goes stale and never shows on more than one row at once.
final matchesWithTopPickProvider = Provider<AsyncValue<List<MovieMatch>>>((
  ref,
) {
  final matchesAsync = ref.watch(matchesProvider);
  final topPickAsync = ref.watch(topPickMovieIdProvider);
  final topPickId = topPickAsync.maybeWhen(data: (v) => v, orElse: () => null);

  return matchesAsync.whenData(
    (rows) => rows.map((row) {
      final movieId = row['movieId'] as int;
      final total = row['totalUsers'] as int;
      return MovieMatch(
        movieId: movieId,
        title: row['title'] as String? ?? '',
        posterPath: row['posterPath'] as String? ?? '',
        voteAverage: row['voteAverage'] as String? ?? '0.0',
        releaseDate: row['releaseDate'] as String? ?? '',
        overview: row['overview'] as String? ?? '', // ← Added
        totalUsers: total,
        isTopPick: movieId == topPickId,
      );
    }).toList(),
  );
});
