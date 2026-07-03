import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebook_library_frontend/core/error/exceptions.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/network/network_info.dart';
import 'package:ebook_library_frontend/features/ebooks/data/datasources/ebook_remote_data_source.dart';
import 'package:ebook_library_frontend/features/ebooks/data/models/ebook_model.dart';
import 'package:ebook_library_frontend/features/ebooks/data/repositories/ebook_repository_impl.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

class MockRemoteDataSource extends Mock implements EbookRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late EbookRepositoryImpl repository;

  EbookModel sampleEbook({int id = 1}) => EbookModel(
        id: id,
        title: 'Clean Code',
        fileType: EbookFileType.pdf,
        downloadUrl: 'http://localhost:3000/api/v1/ebooks/$id/download',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    remote = MockRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = EbookRepositoryImpl(remoteDataSource: remote, networkInfo: networkInfo);
  });

  group('connectivity guard', () {
    test('returns NoInternetFailure immediately when offline, without calling the data source', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getEbook(1);

      expect(result.isSuccess, isFalse);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<NoInternetFailure>()),
      );
      verifyNever(() => remote.getEbook(any()));
    });
  });

  group('exception -> failure mapping', () {
    setUp(() {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    });

    test('NotFoundException -> NotFoundFailure', () async {
      when(() => remote.getEbook(1)).thenThrow(const NotFoundException('not found'));

      final result = await repository.getEbook(1);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<NotFoundFailure>()),
      );
    });

    test('ValidationException -> ValidationFailure carrying the same messages', () async {
      when(() => remote.uploadEbook(
            title: any(named: 'title'),
            author: any(named: 'author'),
            description: any(named: 'description'),
            filePath: any(named: 'filePath'),
            coverImagePath: any(named: 'coverImagePath'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(const ValidationException(["Title can't be blank"]));

      final result = await repository.uploadEbook(title: '', filePath: '/tmp/x.pdf');

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).errors, ["Title can't be blank"]);
        },
      );
    });

    test('ServerException -> ServerFailure', () async {
      when(() => remote.deleteEbook(1)).thenThrow(const ServerException('boom'));

      final result = await repository.deleteEbook(1);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<ServerFailure>()),
      );
    });

    test('unexpected exception -> UnknownFailure (never leaks raw exceptions)', () async {
      when(() => remote.getEbook(1)).thenThrow(StateError('boom'));

      final result = await repository.getEbook(1);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<UnknownFailure>()),
      );
    });
  });

  group('retry behavior for read-only calls', () {
    setUp(() {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    });

    test('retries once on a timeout and succeeds on the second attempt', () async {
      var callCount = 0;
      when(() => remote.getEbook(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw const TimeoutException();
        return sampleEbook();
      });

      final result = await repository.getEbook(1);

      expect(result.isSuccess, isTrue);
      expect(callCount, 2);
    });

    test('gives up after the retry budget is exhausted', () async {
      when(() => remote.getEbook(1)).thenThrow(const TimeoutException());

      final result = await repository.getEbook(1);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<TimeoutFailure>()),
      );
      verify(() => remote.getEbook(1)).called(2); // 1 initial + 1 retry
    });

    test('does NOT retry a write call (delete) on timeout', () async {
      when(() => remote.deleteEbook(1)).thenThrow(const TimeoutException());

      final result = await repository.deleteEbook(1);

      result.when(
        success: (_) => fail('expected failure'),
        failure: (failure) => expect(failure, isA<TimeoutFailure>()),
      );
      verify(() => remote.deleteEbook(1)).called(1); // no retry for writes
    });
  });
}
