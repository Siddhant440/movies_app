enum MediaCategory { trendingMovies, topRatedMovies, popularTvShows }

extension MediaCategoryX on MediaCategory {
  String get label {
    switch (this) {
      case MediaCategory.trendingMovies:
        return 'Trending Movies';
      case MediaCategory.topRatedMovies:
        return 'Top Rated Movies';
      case MediaCategory.popularTvShows:
        return 'Popular TV Shows';
    }
  }

  String get endpoint {
    switch (this) {
      case MediaCategory.trendingMovies:
        return '/trending/movie/day';
      case MediaCategory.topRatedMovies:
        return '/movie/top_rated';
      case MediaCategory.popularTvShows:
        return '/tv/popular';
    }
  }

  // Used as a stable key when caching this category's results locally.
  String get cacheKey {
    switch (this) {
      case MediaCategory.trendingMovies:
        return 'trending_movies';
      case MediaCategory.topRatedMovies:
        return 'top_rated_movies';
      case MediaCategory.popularTvShows:
        return 'popular_tv_shows';
    }
  }

  bool get isTvShow => this == MediaCategory.popularTvShows;
}
