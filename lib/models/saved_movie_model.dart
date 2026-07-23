import 'package:movieApp/models/details_model.dart';

class SavedMovie {
  final String localId;
  final String userLocalId;
  final int movieId;
  final String title;
  final String posterPath;
  final String overview;
  final String releaseDate;
  final String voteAverage;
  final bool isSynced;

  const SavedMovie({
    required this.localId,
    required this.userLocalId,
    required this.movieId,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'userLocalId': userLocalId,
      'movieId': movieId,
      'title': title,
      'posterPath': posterPath,
      'overview': overview,
      'releaseDate': releaseDate,
      'voteAverage': voteAverage,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory SavedMovie.fromMap(Map<String, dynamic> map) {
    return SavedMovie(
      localId: map['localId'] as String,
      userLocalId: map['userLocalId'] as String,
      movieId: map['movieId'] as int,
      title: map['title'] as String,
      posterPath: map['posterPath'] as String? ?? '',
      overview: map['overview'] as String? ?? '',
      releaseDate: map['releaseDate'] as String? ?? '',
      voteAverage: map['voteAverage'] as String? ?? '0.0',
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }
}

/// Lets a [SavedMovie] (local-only record) be opened in the same
/// [DetailsScreen] used for API results, without adding a backdropPath
/// column to the saved_movies table - the poster is reused as the
/// backdrop, matching how it already renders in saved/offline contexts.
class SavedMovieDetails implements DetailsModel {
  final SavedMovie saved;
  const SavedMovieDetails(this.saved);

  @override
  int get id => saved.movieId;
  @override
  String get title => saved.title;
  @override
  String get overview => saved.overview;
  @override
  String get posterPath => saved.posterPath;
  @override
  String get backdropPath => saved.posterPath;
  @override
  String get releaseDate => saved.releaseDate;
  @override
  String get voteAverage => saved.voteAverage;
}
