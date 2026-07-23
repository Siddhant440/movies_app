import 'package:movieApp/models/details_model.dart';

class PaginatedState {
  final List<DetailsModel> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedState copyWith({
    List<DetailsModel>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    Object? error,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}
