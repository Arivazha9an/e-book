import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/search_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/search/search_bloc.dart';

import '../../../../../helpers/test_fixtures.dart';

class MockSearchEbooks extends Mock implements SearchEbooks {}

void main() {
  late MockSearchEbooks searchEbooks;

  setUpAll(() {
    registerFallbackValue(const SearchEbooksParams(query: '', page: 1));
  });

  setUp(() {
    searchEbooks = MockSearchEbooks();
  });

  SearchBloc buildBloc() => SearchBloc(searchEbooks: searchEbooks);

  blocTest<SearchBloc, SearchState>(
    'debounces rapid keystrokes into a single search call',
    build: () {
      when(() => searchEbooks(any())).thenAnswer(
        (_) async => Success(buildPaginatedEbooks(items: [buildEbook(title: 'Clean Code')])),
      );
      return buildBloc();
    },
    act: (bloc) {
      bloc.add(const SearchQueryChanged('c'));
      bloc.add(const SearchQueryChanged('cl'));
      bloc.add(const SearchQueryChanged('cle'));
      bloc.add(const SearchQueryChanged('clean'));
    },
    wait: const Duration(milliseconds: 600),
    verify: (_) {
      verify(() => searchEbooks(any())).called(1);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'emits [loading, success] for a search that finds results',
    build: () {
      when(() => searchEbooks(any())).thenAnswer(
        (_) async => Success(buildPaginatedEbooks(items: [buildEbook(title: 'Clean Code')])),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SearchQueryChanged('clean')),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      isA<SearchState>().having((s) => s.status, 'status', SearchStatus.loading),
      isA<SearchState>()
          .having((s) => s.status, 'status', SearchStatus.success)
          .having((s) => s.results.length, 'results.length', 1),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'resets to idle when the query is cleared',
    build: () {
      when(() => searchEbooks(any())).thenAnswer(
        (_) async => Success(buildPaginatedEbooks(items: [buildEbook()])),
      );
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const SearchQueryChanged('clean'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      bloc.add(const SearchQueryChanged(''));
    },
    wait: const Duration(milliseconds: 500),
    skip: 2,
    expect: () => [const SearchState()],
  );

  blocTest<SearchBloc, SearchState>(
    'emits failure state when the search errors',
    build: () {
      when(() => searchEbooks(any())).thenAnswer((_) async => const Error(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SearchQueryChanged('clean')),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      isA<SearchState>().having((s) => s.status, 'status', SearchStatus.loading),
      isA<SearchState>()
          .having((s) => s.status, 'status', SearchStatus.failure)
          .having((s) => s.failure, 'failure', isA<ServerFailure>()),
    ],
  );

  blocTest<SearchBloc, SearchState>(
    'loads the next page and appends results',
    build: () {
      when(() => searchEbooks(any())).thenAnswer((invocation) async {
        final params = invocation.positionalArguments.first as SearchEbooksParams;
        if (params.page == 1) {
          return Success(buildPaginatedEbooks(
            items: [buildEbook(id: 1)],
            currentPage: 1,
            totalPages: 2,
            totalCount: 2,
          ));
        }
        return Success(buildPaginatedEbooks(
          items: [buildEbook(id: 2)],
          currentPage: 2,
          totalPages: 2,
          totalCount: 2,
        ));
      });
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const SearchQueryChanged('book'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      bloc.add(const SearchNextPageRequested());
    },
    skip: 2,
    expect: () => [
      isA<SearchState>().having((s) => s.status, 'status', SearchStatus.loadingMore),
      isA<SearchState>()
          .having((s) => s.results.map((e) => e.id), 'ids', [1, 2])
          .having((s) => s.hasNextPage, 'hasNextPage', false),
    ],
  );
}
