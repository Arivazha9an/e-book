import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

/// Fetches a single ebook's latest details — used by the detail/reader
/// screens to refresh data (including current reading progress) rather
/// than relying solely on the possibly-stale copy passed via navigation.
class GetEbook implements UseCase<Ebook, int> {
  GetEbook(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<Ebook>> call(int ebookId) => _repository.getEbook(ebookId);
}
