import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:movieApp/data/media_category.dart';
import 'package:movieApp/data/media_repository.dart';
import 'package:movieApp/state/paginated_state.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return TmdbMediaRepository(ref.watch(httpClientProvider));
});

class PaginatedMediaNotifier extends StateNotifier<PaginatedState> {
  final MediaRepository _repository;
  final MediaCategory _category;

  PaginatedMediaNotifier(this._repository, this._category)
      : super(const PaginatedState()) {
    fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newItems = await _repository.fetchPage(_category, state.page);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        page: state.page + 1,
        isLoading: false,
        hasMore: newItems.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedState();
    await fetchNextPage();
  }
}

final paginatedMediaProvider = StateNotifierProvider.family<
    PaginatedMediaNotifier, PaginatedState, MediaCategory>((ref, category) {
  return PaginatedMediaNotifier(ref.watch(mediaRepositoryProvider), category);
});
