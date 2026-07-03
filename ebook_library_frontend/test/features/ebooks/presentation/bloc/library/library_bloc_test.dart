import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/delete_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_bloc.dart';

import '../../../../../helpers/test_fixtures.dart';

class MockGetEbooks extends Mock implements GetEbooks {}

class MockDeleteEbook extends Mock implements DeleteEbook {}

void main() {
  late MockGetEbooks getEbooks;
  late MockDeleteEbook deleteEbook;

  setUpAll(() {
    registerFallbackValue(const GetEbooksParams(page: 1));
  });

  setUp(() {
    getEbooks = MockGetEbooks();
    deleteEbook = MockDeleteEbook();
  });

  LibraryBloc buildBloc() => LibraryBloc(getEbooks: getEbooks, deleteEbook: deleteEbook);

  group('LibraryStarted', () {
    blocTest<LibraryBloc, LibraryState>(
      'emits [loading, success] when the first page loads successfully',
      build: () {
        when(() => getEbooks(any())).thenAnswer(
          (_) async => Success(buildPaginatedEbooks(currentPage: 1, totalPages: 2, totalCount: 21)),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LibraryStarted()),
      expect: () => [
        const LibraryState(status: LibraryStatus.loading),
        isA<LibraryState>()
            .having((s) => s.status, 'status', LibraryStatus.success)
            .having((s) => s.ebooks.length, 'ebooks.length', 1)
            .having((s) => s.hasNextPage, 'hasNextPage', true)
            .having((s) => s.totalCount, 'totalCount', 21),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'emits [loading, failure] when the first page fails and there is no cached data',
      build: () {
        when(() => getEbooks(any())).thenAnswer((_) async => const Error(NoInternetFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LibraryStarted()),
      expect: () => [
        const LibraryState(status: LibraryStatus.loading),
        isA<LibraryState>()
            .having((s) => s.status, 'status', LibraryStatus.failure)
            .having((s) => s.failure, 'failure', isA<NoInternetFailure>()),
      ],
    );
  });

  group('LibraryNextPageRequested', () {
    blocTest<LibraryBloc, LibraryState>(
      'appends the next page and keeps existing items',
      build: () {
        when(() => getEbooks(any())).thenAnswer((invocation) async {
          final params = invocation.positionalArguments.first as GetEbooksParams;
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
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LibraryNextPageRequested());
      },
      skip: 2, // skip [loading, success-with-page-1]
      expect: () => [
        isA<LibraryState>().having((s) => s.status, 'status', LibraryStatus.loadingMore),
        isA<LibraryState>()
            .having((s) => s.ebooks.length, 'ebooks.length', 2)
            .having((s) => s.ebooks.map((e) => e.id), 'ids', [1, 2])
            .having((s) => s.hasNextPage, 'hasNextPage', false),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'does nothing if there is no next page',
      build: () {
        when(() => getEbooks(any())).thenAnswer(
          (_) async => Success(buildPaginatedEbooks(currentPage: 1, totalPages: 1)),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LibraryNextPageRequested());
      },
      skip: 2,
      expect: () => <LibraryState>[],
      verify: (_) {
        verify(() => getEbooks(any())).called(1); // only the initial page-1 call
      },
    );
  });

  group('LibraryEbookDeleted', () {
    blocTest<LibraryBloc, LibraryState>(
      'removes the ebook from the list on success',
      build: () {
        when(() => getEbooks(any())).thenAnswer(
          (_) async => Success(buildPaginatedEbooks(
            items: [buildEbook(id: 1), buildEbook(id: 2)],
            totalCount: 2,
          )),
        );
        when(() => deleteEbook(1)).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LibraryEbookDeleted(1));
      },
      skip: 2,
      expect: () => [
        isA<LibraryState>().having((s) => s.deletingIds, 'deletingIds', {1}),
        isA<LibraryState>()
            .having((s) => s.ebooks.map((e) => e.id), 'remaining ids', [2])
            .having((s) => s.deletingIds, 'deletingIds', isEmpty)
            .having((s) => s.totalCount, 'totalCount', 1),
      ],
    );

    blocTest<LibraryBloc, LibraryState>(
      'keeps the ebook and surfaces the error on failure',
      build: () {
        when(() => getEbooks(any())).thenAnswer(
          (_) async => Success(buildPaginatedEbooks(items: [buildEbook(id: 1)])),
        );
        when(() => deleteEbook(1)).thenAnswer((_) async => const Error(ServerFailure()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const LibraryStarted());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const LibraryEbookDeleted(1));
      },
      skip: 2,
      expect: () => [
        isA<LibraryState>().having((s) => s.deletingIds, 'deletingIds', {1}),
        isA<LibraryState>()
            .having((s) => s.ebooks.length, 'ebooks.length', 1)
            .having((s) => s.deletingIds, 'deletingIds', isEmpty)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
    );
  });
}
