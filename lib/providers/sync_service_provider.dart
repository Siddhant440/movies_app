import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/providers/connectivity_provider.dart';
import 'package:movieApp/providers/user_providers.dart';
import 'package:movieApp/services/local_database_service.dart';
import 'package:movieApp/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService.instance;
  service.start();
  ref.onDispose(service.dispose);

  // Whenever a sync run finishes (isSyncing flips back to false), reload
  // the users list from the local DB so the "pending sync" badge and any
  // server-assigned ids update on screen without a manual refresh.
  final sub = service.isSyncingStream.listen((isSyncing) {
    if (!isSyncing) {
      ref.read(usersProvider.notifier).refreshFromLocal();
    }
  });
  ref.onDispose(sub.cancel);

  return service;
});

final isSyncingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.isSyncingStream;
});

final showCloudIconProvider = FutureProvider.family<bool, String>((ref, userLocalId) async {
  final isOnline = ref.watch(connectivityProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true, // default safe
      );

  if (isOnline) return false; // Never show cloud when online

  final db = LocalDatabaseService.instance;
  final pendingUsers = await db.getPendingUsers();
  final hasPendingUser = pendingUsers.any((u) => u.localId == userLocalId);

  final pendingMovies = await db.getPendingSavedMovies();
  final hasPendingMovies = pendingMovies.any((m) => m.userLocalId == userLocalId);

  return hasPendingUser || hasPendingMovies;
});
