import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class GetEbooksParams {
  const GetEbooksParams({
    required this.page,
    this.perPage = 20,
    this.sort = EbookSort.recent,
    this.fileType,
  });

  final int page;
  final int perPage;
  final EbookSort sort;
  final String? fileType;
}

/// Fetches a single page of the library, newest-first by default.
class GetEbooks implements UseCase<PaginatedResult<Ebook>, GetEbooksParams> {
  GetEbooks(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<PaginatedResult<Ebook>>> call(GetEbooksParams params) {
    return _repository.getEbooks(
      page: params.page,
      perPage: params.perPage,
      sort: params.sort,
      fileType: params.fileType,
    );
  }
}
