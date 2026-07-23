import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:movieApp/core/api_constants.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/services/local_database_service.dart';
import 'package:movieApp/services/sync_service.dart';
import 'package:uuid/uuid.dart';

class UsersState {
  final List<AppUser> users;
  final bool isLoading;
  final bool hasMore;
  final int page;

  const UsersState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
  });

  UsersState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  UsersNotifier() : super(const UsersState()) {
    fetchNextPage();
  }

  final _db = LocalDatabaseService.instance;
  final _uuid = const Uuid();

  static List<AppUser> mergeUsers(
    List<AppUser> localUsers,
    List<AppUser> remoteUsers,
  ) {
    final mergedByKey = <String, AppUser>{};

    for (final user in localUsers) {
      mergedByKey[user.localId] = user;
    }

    for (final user in remoteUsers) {
      final existing = mergedByKey[user.localId];
      if (existing == null) {
        mergedByKey[user.localId] = user;
        continue;
      }

      mergedByKey[user.localId] = AppUser(
        localId: existing.localId,
        remoteId: user.remoteId ?? existing.remoteId,
        firstName: user.firstName.isNotEmpty
            ? user.firstName
            : existing.firstName,
        lastName: user.lastName.isNotEmpty ? user.lastName : existing.lastName,
        email: user.email.isNotEmpty ? user.email : existing.email,
        avatar: user.avatar.isNotEmpty ? user.avatar : existing.avatar,
        isSynced: existing.isSynced || user.isSynced,
        savedCount: existing.savedCount,
      );
    }

    final sortedUsers = mergedByKey.values.toList(growable: false)
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

    return sortedUsers;
  }

  Future<List<AppUser>> _fetchRemoteUsers({required int page}) async {
    final uri = Uri.parse(
      '${ApiConstants.reqresBaseUrl}${ApiConstants.reqresUsersEndpoint}?page=$page',
    );

    final response = await http.get(
      uri,
      headers: {'x-api-key': ApiConstants.reqresApiKey},
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final userList = decoded['data'] as List<dynamic>? ?? const [];

    final users = userList
        .map((item) => AppUser.fromReqresJson(item as Map<String, dynamic>))
        .toList(growable: false);

    for (final user in users) {
      await _db.insertOrReplaceUser(user);
    }

    return users;
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final localUsers = await _db.getUsers();
      final remoteUsers = await _fetchRemoteUsers(page: state.page);

      final sortedUsers = mergeUsers(localUsers, remoteUsers);

      state = state.copyWith(
        users: sortedUsers,
        isLoading: false,
        hasMore: remoteUsers.isNotEmpty,
        page: state.page + 1,
      );
    } catch (e) {
      debugPrint('Fetch users error: $e');

      final localUsers = await _db.getUsers();
      state = state.copyWith(
        users: localUsers,
        isLoading: false,
        hasMore: false,
      );
    }
  }

  Future<void> refreshFromLocal() async {
    final localUsers = await _db.getUsers();
    final sortedUsers = mergeUsers(localUsers, const []);

    state = state.copyWith(users: sortedUsers);
  }

  /// Image 3 + Image 4 behaviour:
  /// - Online  -> save locally AND POST to the API immediately.
  /// - Offline -> save locally with isSynced=false ("pending_sync"); the
  ///              user shows up in the list right away without waiting for
  ///              sync, and SyncService pushes it to the server as soon as
  ///              connectivity returns (see sync_service.dart), writing the
  ///              server-assigned id back to the local record.
  Future<void> addUser({
    required String name,
    required String movieTaste,
  }) async {
    final normalizedName = name.trim();
    final normalizedTaste = movieTaste.trim();

    final connectivity = Connectivity();
    final connectivityResult = await connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    final user = AppUser(
      localId: _uuid.v4(),
      firstName: normalizedName,
      lastName: '',
      email: normalizedTaste,
      avatar: '',
      isSynced: false,
    );

    // Always persist locally first so the profile appears immediately,
    // regardless of connectivity.
    await _db.insertOrReplaceUser(user);

    if (isOnline) {
      try {
        final uri = Uri.parse(
          '${ApiConstants.reqresBaseUrl}${ApiConstants.reqresUsersEndpoint}',
        );

        final requestBody = {'name': normalizedName, 'job': normalizedTaste};

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': ApiConstants.reqresApiKey,
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final remoteId = int.tryParse(body['id']?.toString() ?? '');

          final syncedUser = user.copyWith(isSynced: true);

          await _db.markUserSynced(user.localId, remoteId: remoteId);
          await _db.insertOrReplaceUser(syncedUser);

          final updatedUsers = [
            for (final existing in state.users)
              if (existing.localId == user.localId) syncedUser else existing,
            if (!state.users.any((e) => e.localId == user.localId)) syncedUser,
          ];

          state = state.copyWith(users: updatedUsers);
          return;
        }
      } catch (e) {
        debugPrint('Add user error: $e');
        // Falls through to the pending/local-only branch below.
      }
    }

    // Offline (or the online POST failed): show the user immediately with
    // a pending-sync state; SyncService will push it once online.
    final current = [
      ...state.users,
      if (!state.users.any((e) => e.localId == user.localId)) user,
    ];
    state = state.copyWith(users: current);

    if (isOnline) {
      SyncService.instance.syncAllPending();
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier();
});
