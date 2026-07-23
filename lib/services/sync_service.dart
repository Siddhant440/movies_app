import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/services/local_database_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _db = LocalDatabaseService.instance;
  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySub;

  final _isSyncingController = StreamController<bool>.broadcast();
  Stream<bool> get isSyncingStream => _isSyncingController.stream;

  Future<void> start() async {
    await _tryInitialSync();
    _setupConnectivityListener();
  }

  Future<void> _tryInitialSync() async {
    if (await _isOnline()) {
      await syncAllPending();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySub?.cancel();

    // Automatically sync whenever connectivity is restored.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('Internet connection restored. Starting sync...');
        await syncAllPending();
      }
    });
  }

  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> syncAllPending() async {
    _isSyncingController.add(true);

    debugPrint('\n========================================');
    debugPrint('STARTING OFFLINE DATA SYNC');
    debugPrint('========================================');

    try {
      await _syncPendingUsers();
      await _syncPendingSavedMovies();

      debugPrint('Sync completed successfully.');
    } catch (e, stackTrace) {
      debugPrint('Sync error: $e');
      debugPrint(stackTrace.toString());
    } finally {
      _isSyncingController.add(false);

      debugPrint('========================================');
      debugPrint('🏁 SYNC FINISHED');
      debugPrint('========================================\n');
    }
  }

  Future<void> _syncPendingUsers() async {
    final pendingUsers = await _db.getPendingUsers();

    debugPrint('Pending Users: ${pendingUsers.length}');

    for (final user in pendingUsers) {
      try {
        final uri = Uri.parse(
          '${ApiConstants.reqresBaseUrl}${ApiConstants.reqresUsersEndpoint}',
        );

        final headers = {
          'Content-Type': 'application/json',
          'x-api-key': ApiConstants.reqresApiKey,
        };

        final requestBody = {
          'name': user.fullName,
          'job': user.movieTaste,
        };

        debugPrint('\n========== USER SYNC REQUEST ==========');
        debugPrint('User Local ID : ${user.localId}');
        debugPrint('URL           : $uri');
        debugPrint('Method        : POST');
        debugPrint('Headers       : $headers');
        debugPrint('Request Body  : ${jsonEncode(requestBody)}');

        final response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        );

        debugPrint('========== USER SYNC RESPONSE ==========');
        debugPrint('Status Code   : ${response.statusCode}');
        debugPrint('Response Body : ${response.body}');
        debugPrint('========================================');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;

          final remoteId = int.tryParse(body['id']?.toString() ?? '');

          if (remoteId != null) {
            final syncedUser = user.copyWith(isSynced: true);

            await _db.markUserSynced(
              user.localId,
              remoteId: remoteId,
            );

            await _db.insertOrReplaceUser(syncedUser);

            debugPrint(
              'User ${user.localId} synced successfully. Remote ID: $remoteId',
            );
          } else {
            debugPrint('User synced but no remote ID returned.');
          }
        } else {
          debugPrint(
            'User sync failed. HTTP ${response.statusCode}',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('\n========== USER SYNC ERROR ==========');
        debugPrint('User Local ID : ${user.localId}');
        debugPrint('Error         : $e');
        debugPrint('StackTrace    :');
        debugPrint(stackTrace.toString());
        debugPrint('=====================================');
      }
    }
  }

  Future<void> _syncPendingSavedMovies() async {
    final pendingMovies = await _db.getPendingSavedMovies();

    debugPrint('Pending Movies: ${pendingMovies.length}');

    for (final movie in pendingMovies) {
      try {
        final uri = Uri.parse(
          '${ApiConstants.reqresBaseUrl}/users/${movie.userLocalId}/movies',
        );

        final headers = {
          'Content-Type': 'application/json',
          'x-api-key': ApiConstants.reqresApiKey,
        };

        final requestBody = {
          'localId': movie.localId,
          'movieId': movie.movieId,
          'title': movie.title,
          'posterPath': movie.posterPath,
          'overview': movie.overview,
          'releaseDate': movie.releaseDate,
          'voteAverage': movie.voteAverage,
        };

        debugPrint('\n========== MOVIE SYNC REQUEST ==========');
        debugPrint('Movie Local ID: ${movie.localId}');
        debugPrint('URL           : $uri');
        debugPrint('Method        : POST');
        debugPrint('Headers       : $headers');
        debugPrint('Request Body  : ${jsonEncode(requestBody)}');

        final response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        );

        debugPrint('========== MOVIE SYNC RESPONSE ==========');
        debugPrint('Status Code   : ${response.statusCode}');
        debugPrint('Response Body : ${response.body}');
        debugPrint('=========================================');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _db.markSavedMovieSynced(movie.localId);

          debugPrint(
            'Movie ${movie.localId} synced successfully.',
          );
        } else {
          debugPrint(
            'Movie sync failed. HTTP ${response.statusCode}',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('\n========== MOVIE SYNC ERROR ==========');
        debugPrint('Movie Local ID: ${movie.localId}');
        debugPrint('Error         : $e');
        debugPrint('StackTrace    :');
        debugPrint(stackTrace.toString());
        debugPrint('======================================');
      }
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _isSyncingController.close();
  }
}
