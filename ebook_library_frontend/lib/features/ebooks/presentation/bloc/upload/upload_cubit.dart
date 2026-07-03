import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/upload_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/upload/upload_state.dart';

export 'upload_state.dart';

/// A [Cubit] rather than a full [Bloc] since the upload screen only needs
/// simple imperative calls (`submit`, `reset`) rather than a stream of
/// external events.
class UploadCubit extends Cubit<UploadState> {
  UploadCubit({required UploadEbook uploadEbook})
      : _uploadEbook = uploadEbook,
        super(const UploadState());

  final UploadEbook _uploadEbook;

  Future<void> submit({
    required String title,
    String? author,
    String? description,
    required String filePath,
    String? coverImagePath,
  }) async {
    if (title.trim().isEmpty) {
      emit(state.copyWith(
        status: UploadStatus.failure,
        failure: ValidationFailure(['Please give your ebook a title.']),
      ));
      return;
    }

    emit(state.copyWith(
        status: UploadStatus.uploading, progress: 0.0, clearFailure: true));

    final result = await _uploadEbook(UploadEbookParams(
      title: title.trim(),
      author: author?.trim(),
      description: description?.trim(),
      filePath: filePath,
      coverImagePath: coverImagePath,
      onSendProgress: (progress) => emit(state.copyWith(progress: progress)),
    ));

    result.when(
      success: (ebook) => emit(state.copyWith(
          status: UploadStatus.success, uploadedEbook: ebook, progress: 1.0)),
      failure: (failure) =>
          emit(state.copyWith(status: UploadStatus.failure, failure: failure)),
    );
  }

  void reset() => emit(const UploadState());
}
