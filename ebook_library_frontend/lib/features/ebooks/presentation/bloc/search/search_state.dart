import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

enum SearchStatus { idle, loading, loadingMore, success, failure }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.currentPage = 1,
    this.hasNextPage = false,
    this.totalCount = 0,
    this.failure,
  });

  final SearchStatus status;
  final String query;
  final List<Ebook> results;
  final int currentPage;
  final bool hasNextPage;
  final int totalCount;
  final Failure? failure;

  bool get isEmptyResult =>
      status == SearchStatus.success && results.isEmpty && query.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Ebook>? results,
    int? currentPage,
    bool? hasNextPage,
    int? totalCount,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      totalCount: totalCount ?? this.totalCount,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props =>
      [status, query, results, currentPage, hasNextPage, totalCount, failure];
}
