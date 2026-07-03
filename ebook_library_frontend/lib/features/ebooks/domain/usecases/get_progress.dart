import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class GetProgress implements UseCase<ReadingProgress, int> {
  GetProgress(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<ReadingProgress>> call(int ebookId) => _repository.getProgress(ebookId);
}
