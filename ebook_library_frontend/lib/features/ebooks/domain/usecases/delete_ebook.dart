import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class DeleteEbook implements UseCase<void, int> {
  DeleteEbook(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<void>> call(int ebookId) => _repository.deleteEbook(ebookId);
}
