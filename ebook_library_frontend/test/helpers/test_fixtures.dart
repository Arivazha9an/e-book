import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';

Ebook buildEbook({
  int id = 1,
  String title = 'Clean Code',
  String? author = 'Robert C. Martin',
  EbookFileType fileType = EbookFileType.pdf,
  ReadingProgress progress = ReadingProgress.empty,
}) {
  return Ebook(
    id: id,
    title: title,
    author: author,
    fileType: fileType,
    downloadUrl: 'http://localhost:3000/api/v1/ebooks/$id/download',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    progress: progress,
  );
}

PaginatedResult<Ebook> buildPaginatedEbooks({
  List<Ebook>? items,
  int currentPage = 1,
  int totalPages = 1,
  int? totalCount,
}) {
  final list = items ?? [buildEbook()];
  return PaginatedResult(
    items: list,
    currentPage: currentPage,
    totalPages: totalPages,
    totalCount: totalCount ?? list.length,
    perPage: 20,
  );
}
