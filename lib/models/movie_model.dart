import 'package:movieApp/models/details_model.dart';

class Movie implements DetailsModel {
  @override
  final int id;
  @override
  final String title;
  @override
  final String overview;
  @override
  final String posterPath;
  @override
  final String backdropPath;
  @override
  final String releaseDate;
  @override
  final String voteAverage;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: json['release_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toString(),
    );
  }
}
