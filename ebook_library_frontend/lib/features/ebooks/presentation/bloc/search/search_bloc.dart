import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/search_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/search/search_event.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/search/search_state.dart';

export 'search_event.dart';
export 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchEbooks searchEbooks})
      : _searchEbooks = searchEbooks,
        super(const SearchState()) {
    // debounce(): waits for a lull in keystrokes before letting an event
    // through. switchMap(): if a *new* query event arrives while a
    // previous search is still being handled, the previous handler is
    // cancelled — so a fast typist never sees a late, stale result flash
    // in after a newer one.
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) =>
          events.debounce(_debounceDuration).switchMap(mapper),
    );
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchCleared>(_onCleared);
  }

  final SearchEbooks _searchEbooks;
  static const _perPage = 20;
  static const _debounceDuration = Duration(milliseconds: 400);

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: query, clearFailure: true));

    final result = await _searchEbooks(SearchEbooksParams(query: query, page: 1, perPage: _perPage));

    result.when(
      success: (paginated) => emit(state.copyWith(
        status: SearchStatus.success,
        results: paginated.items,
        currentPage: paginated.currentPage,
        hasNextPage: paginated.hasNextPage,
        totalCount: paginated.totalCount,
      )),
      failure: (failure) => emit(state.copyWith(status: SearchStatus.failure, failure: failure)),
    );
  }

  Future<void> _onNextPageRequested(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (state.status == SearchStatus.loadingMore || !state.hasNextPage) return;
    if (state.query.isEmpty) return;

    emit(state.copyWith(status: SearchStatus.loadingMore));

    final result = await _searchEbooks(
      SearchEbooksParams(query: state.query, page: state.currentPage + 1, perPage: _perPage),
    );

    result.when(
      success: (paginated) => emit(state.copyWith(
        status: SearchStatus.success,
        results: [...state.results, ...paginated.items],
        currentPage: paginated.currentPage,
        hasNextPage: paginated.hasNextPage,
        totalCount: paginated.totalCount,
      )),
      failure: (failure) => emit(state.copyWith(status: SearchStatus.success, failure: failure)),
    );
  }

  Future<void> _onCleared(SearchCleared event, Emitter<SearchState> emit) async {
    emit(const SearchState());
  }
}
