import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/models/saved_movie_model.dart';

class LocalDatabaseService {
  LocalDatabaseService._();
  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _database;

  /// Fires (with no payload) every time a row is inserted into or removed
  /// from saved_movies. [watchMatches] and [watchTopPickMovieId] listen to
  /// this to stay live without polling or relying on manual provider
  /// invalidation.
  final StreamController<void> _savedMoviesChanges =
      StreamController<void>.broadcast();

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final db = await _openDatabase();
    _database = db;
    return db;
  }

  Future<Database> _openDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'movie_app.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            localId TEXT PRIMARY KEY,
            remoteId INTEGER,
            firstName TEXT,
            lastName TEXT,
            email TEXT,
            avatar TEXT,
            isSynced INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE saved_movies (
            localId TEXT PRIMARY KEY,
            userLocalId TEXT NOT NULL,
            movieId INTEGER NOT NULL,
            title TEXT,
            posterPath TEXT,
            overview TEXT,
            releaseDate TEXT,
            voteAverage TEXT,
            isSynced INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            UNIQUE(userLocalId, movieId)
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_media (
            categoryKey TEXT NOT NULL,
            page INTEGER NOT NULL,
            movieId INTEGER NOT NULL,
            title TEXT,
            overview TEXT,
            posterPath TEXT,
            backdropPath TEXT,
            releaseDate TEXT,
            voteAverage TEXT,
            isTvShow INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            PRIMARY KEY (categoryKey, movieId)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_media (
              categoryKey TEXT NOT NULL,
              page INTEGER NOT NULL,
              movieId INTEGER NOT NULL,
              title TEXT,
              overview TEXT,
              posterPath TEXT,
              backdropPath TEXT,
              releaseDate TEXT,
              voteAverage TEXT,
              isTvShow INTEGER NOT NULL DEFAULT 0,
              createdAt TEXT NOT NULL,
              PRIMARY KEY (categoryKey, movieId)
            )
          ''');
        }
      },
    );
  }

  // ---------------- Users ----------------

  Future<void> insertOrReplaceUser(AppUser user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
Future<List<AppUser>> getUsers() async {
  final db = await database;
  final rows = await db.rawQuery('''
    SELECT u.*, COALESCE(COUNT(s.localId), 0) AS savedCount
    FROM users u
    LEFT JOIN saved_movies s ON s.userLocalId = u.localId
    GROUP BY u.localId
    ORDER BY 
      u.firstName COLLATE NOCASE ASC, 
      u.lastName COLLATE NOCASE ASC
  ''');

  return rows.map((map) => AppUser.fromLocalMap(map)).toList(growable: false);
}
  // Future<List<AppUser>> getUsers() async {
  //   final db = await database;
  //   final rows = await db.rawQuery('''
  //     SELECT u.*, COALESCE(COUNT(s.localId), 0) AS savedCount
  //     FROM users u
  //     LEFT JOIN saved_movies s ON s.userLocalId = u.localId
  //     GROUP BY u.localId
  //     ORDER BY u.createdAt DESC
  //   ''');

  //   return rows.map((map) => AppUser.fromLocalMap(map)).toList(growable: false);
  // }

  Future<List<AppUser>> getPendingUsers() async {
    final db = await database;
    final rows = await db.query('users', where: 'isSynced = ?', whereArgs: [0]);
    return rows.map(AppUser.fromLocalMap).toList(growable: false);
  }

  Future<void> markUserSynced(String localId, {int? remoteId}) async {
    final db = await database;
    await db.update(
      'users',
      {'isSynced': 1, if (remoteId != null) 'remoteId': remoteId},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  /// Total number of profiles that exist locally. Used to decide whether a
  /// match was saved by literally everyone (the "top pick" highlight).
  Future<int> getUsersCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM users');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  // ---------------- Saved movies ----------------

  Future<void> insertSavedMovie(SavedMovie movie) async {
    final db = await database;
    await db.insert(
      'saved_movies',
      movie.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _savedMoviesChanges.add(null);
  }

  /// Removes a single saved-movie row and notifies [watchMatches] (and
  /// anything else listening) so dependent UI updates immediately.
  Future<void> removeSavedMovie({
    required String userLocalId,
    required int movieId,
  }) async {
    final db = await database;
    await db.delete(
      'saved_movies',
      where: 'userLocalId = ? AND movieId = ?',
      whereArgs: [userLocalId, movieId],
    );
    _savedMoviesChanges.add(null);
  }

  Future<List<SavedMovie>> getSavedMoviesForUser(String userLocalId) async {
    final db = await database;
    final rows = await db.query(
      'saved_movies',
      where: 'userLocalId = ?',
      whereArgs: [userLocalId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(SavedMovie.fromMap).toList(growable: false);
  }

  Future<List<SavedMovie>> getPendingSavedMovies() async {
    final db = await database;
    final rows = await db.query(
      'saved_movies',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return rows.map(SavedMovie.fromMap).toList(growable: false);
  }

  Future<void> markSavedMovieSynced(String localId) async {
    final db = await database;
    await db.update(
      'saved_movies',
      {'isSynced': 1},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

Future<List<Map<String, dynamic>>> getMatches() async {
  final db = await database;
  return db.rawQuery('''
    SELECT 
      sm.movieId, 
      sm.title, 
      sm.posterPath, 
      sm.voteAverage,
      sm.releaseDate,
      sm.overview,
      COUNT(*) AS totalUsers
    FROM saved_movies sm
    GROUP BY sm.movieId, sm.title, sm.posterPath, sm.voteAverage, 
             sm.releaseDate, sm.overview
    HAVING COUNT(*) > 1
    ORDER BY totalUsers DESC, sm.title ASC
  ''');
}

  /// Live view of [getMatches] - reads entirely from the local DB, no
  /// network involved. Emits an initial value immediately, then again
  /// every time a saved-movie row is inserted or removed anywhere in the
  /// app, so the Matches page updates itself with no manual refresh.
  Stream<List<Map<String, dynamic>>> watchMatches() async* {
    yield await getMatches();
    yield* _savedMoviesChanges.stream.asyncMap((_) => getMatches());
  }

  /// The single movieId that currently holds the "Top Pick" title, or null
  /// if nothing has been saved yet. Only one movie can ever be the top pick
  /// at a time: it's whichever movie currently has the highest save count
  /// across all profiles. If another movie's count later exceeds it, that
  /// movie becomes the sole top pick and the previous one loses the badge
  /// immediately (this method always returns exactly one winner, never a
  /// tied group). Ties on save count are broken by whichever movie most
  /// recently reached that count (its latest saved_movies row is newer),
  /// so a movie that just tied/surpassed the incumbent takes over the
  /// badge right away.
  Future<int?> getTopPickMovieId() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT movieId, COUNT(*) AS cnt, MAX(createdAt) AS lastSavedAt
      FROM saved_movies
      GROUP BY movieId
      ORDER BY cnt DESC, lastSavedAt DESC
      LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return rows.first['movieId'] as int;
  }

  /// Live view of [getTopPickMovieId] - re-emits on every save/unsave so
  /// the top-pick badge moves to the new winner (and disappears from the
  /// old one) everywhere in the app at once.
  Stream<int?> watchTopPickMovieId() async* {
    yield await getTopPickMovieId();
    yield* _savedMoviesChanges.stream.asyncMap((_) => getTopPickMovieId());
  }

  /// Returns every [AppUser] who has saved [movieId], ordered by when they
  /// saved it (most recent first). Used by the Details screen to show
  /// "N users want to watch this" with a small row of their avatars.
  Future<List<AppUser>> getUsersWhoSavedMovie(int movieId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT u.*, COALESCE(uc.savedCount, 0) AS savedCount
      FROM saved_movies sm
      INNER JOIN users u ON u.localId = sm.userLocalId
      LEFT JOIN (
        SELECT userLocalId, COUNT(*) AS savedCount
        FROM saved_movies
        GROUP BY userLocalId
      ) uc ON uc.userLocalId = u.localId
      WHERE sm.movieId = ?
      ORDER BY sm.createdAt DESC
      ''',
      [movieId],
    );

    return rows.map((map) => AppUser.fromLocalMap(map)).toList(growable: false);
  }

  // ---------------- Cached media (offline browsing support) ----------------

  /// Persists a fetched page of movies/tv-shows for [categoryKey] so the
  /// list can still be rendered when the device goes offline later.
  Future<void> cacheMediaPage({
    required String categoryKey,
    required int page,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'cached_media',
        {
          'categoryKey': categoryKey,
          'page': page,
          'movieId': item['id'],
          'title': item['title'],
          'overview': item['overview'],
          'posterPath': item['posterPath'],
          'backdropPath': item['backdropPath'],
          'releaseDate': item['releaseDate'],
          'voteAverage': item['voteAverage'],
          'isTvShow': item['isTvShow'] == true ? 1 : 0,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Returns every cached item for [categoryKey], ordered the way it was
  /// fetched (page, then insertion order), so the offline list looks the
  /// same as the online one.
  Future<List<Map<String, dynamic>>> getCachedMedia(String categoryKey) async {
    final db = await database;
    return db.query(
      'cached_media',
      where: 'categoryKey = ?',
      whereArgs: [categoryKey],
      orderBy: 'page ASC, createdAt ASC',
    );
  }

  Future<int> getCachedMediaMaxPage(String categoryKey) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT MAX(page) AS maxPage FROM cached_media WHERE categoryKey = ?',
      [categoryKey],
    );
    final value = rows.first['maxPage'];
    return value == null ? 0 : value as int;
  }
}
