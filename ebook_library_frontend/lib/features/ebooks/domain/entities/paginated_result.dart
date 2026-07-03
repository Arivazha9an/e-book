import 'package:equatable/equatable.dart';

/// Generic wrapper for a single page of results, mirroring the backend's
/// `{ data, meta }` envelope. Used for both the plain listing and search.
class PaginatedResult<T> extends Equatable {
  const PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasNextPage => currentPage < totalPages;

  static PaginatedResult<T> empty<T>() => PaginatedResult<T>(
        items: const [],
        currentPage: 1,
        totalPages: 1,
        totalCount: 0,
        perPage: 20,
      );

  @override
  List<Object?> get props => [items, currentPage, totalPages, totalCount, perPage];
}
