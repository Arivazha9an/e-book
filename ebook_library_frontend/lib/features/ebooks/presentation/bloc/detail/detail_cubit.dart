import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/delete_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_download_url.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/detail/detail_state.dart';

export 'detail_state.dart';

class DetailCubit extends Cubit<DetailState> {
  DetailCubit({
    required GetEbook getEbook,
    required DeleteEbook deleteEbook,
    required GetDownloadUrl getDownloadUrl,
    required int ebookId,
    Ebook? initial,
  })  : _getEbook = getEbook,
        _deleteEbook = deleteEbook,
        _getDownloadUrl = getDownloadUrl,
        _ebookId = ebookId,
        super(DetailState(
          status: initial != null ? DetailStatus.success : DetailStatus.loading,
          ebook: initial,
        ));

  final GetEbook _getEbook;
  final DeleteEbook _deleteEbook;
  final GetDownloadUrl _getDownloadUrl;
  final int _ebookId;

  Future<void> load() async {
    emit(state.copyWith(
      status: state.ebook == null ? DetailStatus.loading : state.status,
      clearFailure: true,
    ));

    final result = await _getEbook(_ebookId);

    result.when(
      success: (ebook) => emit(state.copyWith(status: DetailStatus.success, ebook: ebook)),
      failure: (failure) {
        // If we already had cached data (passed in via navigation), keep
        // showing it and just note the refresh failed, rather than
        // blanking the whole screen.
        emit(state.copyWith(
          status: state.ebook != null ? DetailStatus.success : DetailStatus.failure,
          failure: failure,
        ));
      },
    );
  }

  Future<void> delete() async {
    emit(state.copyWith(action: DetailAction.deleting, clearFailure: true));

    final result = await _deleteEbook(_ebookId);

    result.when(
      success: (_) => emit(state.copyWith(action: DetailAction.none, deleted: true)),
      failure: (failure) =>
          emit(state.copyWith(action: DetailAction.none, failure: failure)),
    );
  }

  Future<String?> resolveDownloadUrl() async {
    emit(state.copyWith(action: DetailAction.preparingDownload, clearFailure: true));

    final result = await _getDownloadUrl(_ebookId);

    String? url;
    result.when(
      success: (value) => url = value,
      failure: (failure) => emit(state.copyWith(failure: failure)),
    );

    emit(state.copyWith(action: DetailAction.none));
    return url;
  }
}
