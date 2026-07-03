import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class UpdateProgressParams {
  const UpdateProgressParams({
    required this.ebookId,
    this.currentPage,
    this.totalPages,
    this.lastPosition,
  });

  final int ebookId;
  final int? currentPage;
  final int? totalPages;
  final double? lastPosition;
}

/// Called (debounced) by the reader screen so the backend always has the
/// latest position — this is what makes "continue where they left off"
/// work when the book is reopened later, even on a different session.
class UpdateProgress implements UseCase<ReadingProgress, UpdateProgressParams> {
  UpdateProgress(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<ReadingProgress>> call(UpdateProgressParams params) {
    return _repository.updateProgress(
      id: params.ebookId,
      currentPage: params.currentPage,
      totalPages: params.totalPages,
      lastPosition: params.lastPosition,
    );
  }
}
