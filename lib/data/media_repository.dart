import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/data/media_category.dart';
import 'package:movieApp/models/details_model.dart';
import 'package:movieApp/models/movie_model.dart';
import 'package:movieApp/services/local_database_service.dart';

abstract class MediaRepository {
  Future<List<DetailsModel>> fetchPage(MediaCategory category, int page);
}

/// Fetches from TMDB and, per the offline requirement, caches every fetched
/// item to the local database (Page 03). If the network call fails (e.g. no
/// internet) it falls back to whatever was previously cached for that
/// category/page so the Movies list still renders offline.
class TmdbMediaRepository implements MediaRepository {
  final http.Client client;
  final _db = LocalDatabaseService.instance;

  TmdbMediaRepository(this.client);

  @override
  Future<List<DetailsModel>> fetchPage(MediaCategory category, int page) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${category.endpoint}'
        '?language=en-US&page=$page&api_key=${ApiConstants.apiKey}',
      );

      final response = await client.get(uri);
      if (response.statusCode != 200) {
        return _fallbackToCache(category, page);
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List<dynamic>? ?? []);

      final items = results
          .map<DetailsModel>(
            (item) => 
                Movie.fromJson(item as Map<String, dynamic>),
          )
          .where((m) => m.posterPath.isNotEmpty && m.title.isNotEmpty)
          .toList();

      // Persist locally so the same page is available with no internet.
      await _db.cacheMediaPage(
        categoryKey: category.cacheKey,
        page: page,
        items: items
            .map(
              (m) => {
                'id': m.id,
                'title': m.title,
                'overview': m.overview,
                'posterPath': m.posterPath,
                'backdropPath': m.backdropPath,
                'releaseDate': m.releaseDate,
                'voteAverage': m.voteAverage,
                'isTvShow': category.isTvShow,
              },
            )
            .toList(),
      );

      return items;
    } catch (_) {
      return _fallbackToCache(category, page);
    }
  }

  Future<List<DetailsModel>> _fallbackToCache(
    MediaCategory category,
    int page,
  ) async {
    // Only page 1 is ever requested while offline in practice (pagination
    // stops once a network fetch fails), but guard on the max cached page
    // anyway so nothing breaks if fetchNextPage is called again offline.
    final maxCachedPage = await _db.getCachedMediaMaxPage(category.cacheKey);
    if (page > maxCachedPage && maxCachedPage != 0) return const [];

    final rows = await _db.getCachedMedia(category.cacheKey);
    return rows
        .map<DetailsModel>(
          (row) => Movie(
                  id: row['movieId'] as int,
                  title: row['title'] as String? ?? '',
                  overview: row['overview'] as String? ?? '',
                  posterPath: row['posterPath'] as String? ?? '',
                  backdropPath: row['backdropPath'] as String? ?? '',
                  releaseDate: row['releaseDate'] as String? ?? '',
                  voteAverage: row['voteAverage'] as String? ?? '0.0',
                ),
        )
        .toList();
  }
}
