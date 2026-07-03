import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/delete_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_event.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_state.dart';

export 'library_event.dart';
export 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({
    required GetEbooks getEbooks,
    required DeleteEbook deleteEbook,
  })  : _getEbooks = getEbooks,
        _deleteEbook = deleteEbook,
        super(const LibraryState()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryRefreshed>(_onRefreshed);
    on<LibraryNextPageRequested>(_onNextPageRequested);
    on<LibrarySortChanged>(_onSortChanged);
    on<LibraryFileTypeFilterChanged>(_onFileTypeFilterChanged);
    on<LibraryEbookDeleted>(_onEbookDeleted);
  }

  final GetEbooks _getEbooks;
  final DeleteEbook _deleteEbook;

  static const _perPage = 20;

  Future<void> _onStarted(LibraryStarted event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.loading, clearFailure: true));
    await _loadPage(page: 1, emit: emit, replace: true);
  }

  Future<void> _onRefreshed(LibraryRefreshed event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.refreshing, clearFailure: true));
    await _loadPage(page: 1, emit: emit, replace: true);
  }

  Future<void> _onNextPageRequested(
    LibraryNextPageRequested event,
    Emitter<LibraryState> emit,
  ) async {
    // Guard against duplicate triggers from rapid scroll events, or firing
    // once there's nothing left to load.
    if (state.status == LibraryStatus.loadingMore || !state.hasNextPage) return;
    if (state.status != LibraryStatus.success) return;

    emit(state.copyWith(status: LibraryStatus.loadingMore));
    await _loadPage(page: state.currentPage + 1, emit: emit, replace: false);
  }

  Future<void> _onSortChanged(LibrarySortChanged event, Emitter<LibraryState> emit) async {
    if (event.sort == state.sort) return;
    emit(state.copyWith(sort: event.sort, status: LibraryStatus.loading, clearFailure: true));
    await _loadPage(page: 1, emit: emit, replace: true);
  }

  Future<void> _onFileTypeFilterChanged(
    LibraryFileTypeFilterChanged event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(
      fileType: event.fileType,
      clearFileType: event.fileType == null,
      status: LibraryStatus.loading,
      clearFailure: true,
    ));
    await _loadPage(page: 1, emit: emit, replace: true);
  }

  Future<void> _onEbookDeleted(LibraryEbookDeleted event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(deletingIds: {...state.deletingIds, event.ebookId}));

    final result = await _deleteEbook(event.ebookId);

    result.when(
      success: (_) {
        final updated = state.ebooks.where((e) => e.id != event.ebookId).toList();
        emit(state.copyWith(
          ebooks: updated,
          totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
          deletingIds: {...state.deletingIds}..remove(event.ebookId),
        ));
      },
      failure: (failure) {
        // Deletion failed — surface the error but keep the book in the
        // list (don't optimistically remove it before we know it worked).
        emit(state.copyWith(
          deletingIds: {...state.deletingIds}..remove(event.ebookId),
          failure: failure,
        ));
      },
    );
  }

  Future<void> _loadPage({
    required int page,
    required Emitter<LibraryState> emit,
    required bool replace,
  }) async {
    final result = await _getEbooks(GetEbooksParams(
      page: page,
      perPage: _perPage,
      sort: state.sort,
      fileType: state.fileType,
    ));

    result.when(
      success: (paginated) {
        emit(state.copyWith(
          status: LibraryStatus.success,
          ebooks: replace ? paginated.items : [...state.ebooks, ...paginated.items],
          currentPage: paginated.currentPage,
          hasNextPage: paginated.hasNextPage,
          totalCount: paginated.totalCount,
          clearFailure: true,
        ));
      },
      failure: (failure) {
        emit(state.copyWith(
          // Only go to a full failure screen if we have nothing to show;
          // otherwise keep existing content visible and just report the
          // error (e.g. a "couldn't load more" toast).
          status: state.ebooks.isEmpty ? LibraryStatus.failure : LibraryStatus.success,
          failure: failure,
        ));
      },
    );
  }
}
