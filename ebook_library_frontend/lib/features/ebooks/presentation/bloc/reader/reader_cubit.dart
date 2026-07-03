import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/core/utils/debouncer.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/update_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/reader/reader_state.dart';

export 'reader_state.dart';

/// Drives the "continue where they left off" behavior for a single reading
/// session. The page/scroll position itself lives in the PDF viewer
/// widget; this cubit's job is purely to persist it back to the backend
/// without hammering the API on every single page turn.
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required UpdateProgress updateProgress,
    required int ebookId,
    required int initialPage,
  })  : _updateProgress = updateProgress,
        super(ReaderState(ebookId: ebookId, initialPage: initialPage));

  final UpdateProgress _updateProgress;
  final Debouncer _debouncer = Debouncer(delay: const Duration(seconds: 3));

  /// Call this on every page change / scroll update. It's cheap and safe
  /// to call often — the debouncer ensures only one network call fires
  /// after ~3 seconds of the user settling on a page, not one per event.
  void onPositionChanged({required int currentPage, int? totalPages, double? lastPosition}) {
    _debouncer.run(() => _save(currentPage: currentPage, totalPages: totalPages, lastPosition: lastPosition));
  }

  /// Call this immediately (no debounce) when the reader screen is closed,
  /// so the final position is never lost to an un-fired debounce timer.
  Future<void> saveImmediately({
    required int currentPage,
    int? totalPages,
    double? lastPosition,
  }) {
    return _save(currentPage: currentPage, totalPages: totalPages, lastPosition: lastPosition);
  }

  Future<void> _save({required int currentPage, int? totalPages, double? lastPosition}) async {
    emit(state.copyWith(saveStatus: ReaderSaveStatus.saving));

    final result = await _updateProgress(UpdateProgressParams(
      ebookId: state.ebookId,
      currentPage: currentPage,
      totalPages: totalPages,
      lastPosition: lastPosition,
    ));

    result.when(
      success: (_) => emit(state.copyWith(saveStatus: ReaderSaveStatus.saved, clearFailure: true)),
      failure: (failure) => emit(state.copyWith(saveStatus: ReaderSaveStatus.failed, failure: failure)),
    );
  }

  @override
  Future<void> close() {
    _debouncer.dispose();
    return super.close();
  }
}
