import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

enum LibraryStatus {
  /// Nothing loaded yet.
  initial,

  /// First page loading — show the full skeleton/shimmer state.
  loading,

  /// Have data, fetching another page at the bottom — show a small footer spinner.
  loadingMore,

  /// Pull-to-refresh in progress — keep showing existing data underneath.
  refreshing,

  /// Have data (possibly empty) and nothing in flight.
  success,

  /// First-page load failed and there's no data to fall back on.
  failure,
}

class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.ebooks = const [],
    this.currentPage = 1,
    this.hasNextPage = true,
    this.totalCount = 0,
    this.sort = EbookSort.recent,
    this.fileType,
    this.failure,
    this.deletingIds = const {},
  });

  final LibraryStatus status;
  final List<Ebook> ebooks;
  final int currentPage;
  final bool hasNextPage;
  final int totalCount;
  final EbookSort sort;
  final String? fileType;
  final Failure? failure;

  /// IDs currently being deleted, so the shelf can show an inline spinner
  /// on that specific card instead of blocking the whole screen.
  final Set<int> deletingIds;

  bool get isEmpty => status == LibraryStatus.success && ebooks.isEmpty;

  LibraryState copyWith({
    LibraryStatus? status,
    List<Ebook>? ebooks,
    int? currentPage,
    bool? hasNextPage,
    int? totalCount,
    EbookSort? sort,
    String? fileType,
    bool clearFileType = false,
    Failure? failure,
    bool clearFailure = false,
    Set<int>? deletingIds,
  }) {
    return LibraryState(
      status: status ?? this.status,
      ebooks: ebooks ?? this.ebooks,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      sort: sort ?? this.sort,
      fileType: clearFileType ? null : (fileType ?? this.fileType),
      failure: clearFailure ? null : (failure ?? this.failure),
      deletingIds: deletingIds ?? this.deletingIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        ebooks,
        currentPage,
        hasNextPage,
        totalCount,
        sort,
        fileType,
        failure,
        deletingIds,
      ];
}
