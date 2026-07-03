import 'package:ebook_library_frontend/features/ebooks/data/models/ebook_model.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';

/// Parses the `{ data: [...], meta: {...} }` envelope returned by both the
/// listing and search endpoints.
class PaginatedEbooksResponse {
  const PaginatedEbooksResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory PaginatedEbooksResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((e) => EbookModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return PaginatedEbooksResponse(
      items: data,
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
      totalCount: (meta['total_count'] as num?)?.toInt() ?? data.length,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 20,
    );
  }

  final List<EbookModel> items;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  PaginatedResult<EbookModel> toEntity() => PaginatedResult(
        items: items,
        currentPage: currentPage,
        totalPages: totalPages,
        totalCount: totalCount,
        perPage: perPage,
      );
}
