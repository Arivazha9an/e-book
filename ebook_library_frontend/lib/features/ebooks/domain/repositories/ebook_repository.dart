import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';

enum EbookSort { recent, oldest, title, author, recentlyRead }

/// Contract the domain layer depends on. The concrete implementation
/// (in `data/repositories`) is the only place that knows about Dio, JSON,
/// or HTTP status codes.
abstract class EbookRepository {
  Future<Result<PaginatedResult<Ebook>>> getEbooks({
    required int page,
    int perPage,
    EbookSort sort,
    String? fileType,
  });

  Future<Result<PaginatedResult<Ebook>>> searchEbooks({
    required String query,
    required int page,
    int perPage,
    EbookSort sort,
    String? fileType,
  });

  Future<Result<Ebook>> getEbook(int id);

  Future<Result<Ebook>> uploadEbook({
    required String title,
    String? author,
    String? description,
    required String filePath,
    String? coverImagePath,
    void Function(double progress)? onSendProgress,
  });

  Future<Result<void>> deleteEbook(int id);

  /// Returns the direct file URL to download/stream (the backend
  /// redirects `.../download` to a signed blob URL).
  Future<Result<String>> getDownloadUrl(int id);

  Future<Result<ReadingProgress>> getProgress(int id);

  Future<Result<ReadingProgress>> updateProgress({
    required int id,
    int? currentPage,
    int? totalPages,
    double? lastPosition,
  });
}
