import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class SearchEbooksParams {
  const SearchEbooksParams({
    required this.query,
    required this.page,
    this.perPage = 20,
    this.sort = EbookSort.recent,
    this.fileType,
  });

  final String query;
  final int page;
  final int perPage;
  final EbookSort sort;
  final String? fileType;
}

/// Searches the library by title/author/filename, paginated the same way
/// as the plain listing.
class SearchEbooks implements UseCase<PaginatedResult<Ebook>, SearchEbooksParams> {
  SearchEbooks(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<PaginatedResult<Ebook>>> call(SearchEbooksParams params) {
    return _repository.searchEbooks(
      query: params.query,
      page: params.page,
      perPage: params.perPage,
      sort: params.sort,
      fileType: params.fileType,
    );
  }
}
