import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class GetDownloadUrl implements UseCase<String, int> {
  GetDownloadUrl(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<String>> call(int ebookId) => _repository.getDownloadUrl(ebookId);
}
