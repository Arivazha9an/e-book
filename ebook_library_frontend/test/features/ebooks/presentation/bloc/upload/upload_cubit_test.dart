import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/upload_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/upload/upload_cubit.dart';

import '../../../../../helpers/test_fixtures.dart';

class MockUploadEbook extends Mock implements UploadEbook {}

void main() {
  late MockUploadEbook uploadEbook;

  setUpAll(() {
    registerFallbackValue(const UploadEbookParams(title: '', filePath: ''));
  });

  setUp(() {
    uploadEbook = MockUploadEbook();
  });

  UploadCubit buildCubit() => UploadCubit(uploadEbook: uploadEbook);

  blocTest<UploadCubit, UploadState>(
    'emits a validation failure without calling the use case when title is blank',
    build: buildCubit,
    act: (cubit) => cubit.submit(title: '  ', filePath: '/tmp/book.pdf'),
    expect: () => [
      isA<UploadState>()
          .having((s) => s.status, 'status', UploadStatus.failure)
          .having((s) => s.failure, 'failure', isA<ValidationFailure>()),
    ],
    verify: (_) {
      verifyNever(() => uploadEbook(any()));
    },
  );

  blocTest<UploadCubit, UploadState>(
    'emits [uploading, success] when the upload succeeds',
    build: () {
      when(() => uploadEbook(any()))
          .thenAnswer((_) async => Success(buildEbook(title: 'My Book')));
      return buildCubit();
    },
    act: (cubit) => cubit.submit(title: 'My Book', filePath: '/tmp/book.pdf'),
    expect: () => [
      isA<UploadState>()
          .having((s) => s.status, 'status', UploadStatus.uploading),
      isA<UploadState>()
          .having((s) => s.status, 'status', UploadStatus.success)
          .having((s) => s.uploadedEbook?.title, 'title', 'My Book'),
    ],
  );

  blocTest<UploadCubit, UploadState>(
    'emits [uploading, failure] when the backend rejects the upload',
    build: () {
      when(() => uploadEbook(any())).thenAnswer(
        (_) async =>
            Error(ValidationFailure(['File must be a PDF or EPUB file'])),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.submit(title: 'Bad File', filePath: '/tmp/book.txt'),
    expect: () => [
      isA<UploadState>()
          .having((s) => s.status, 'status', UploadStatus.uploading),
      isA<UploadState>()
          .having((s) => s.status, 'status', UploadStatus.failure)
          .having((s) => s.failure, 'failure', isA<ValidationFailure>()),
    ],
  );

  blocTest<UploadCubit, UploadState>(
    'reset() returns the cubit to its idle state',
    build: () {
      when(() => uploadEbook(any()))
          .thenAnswer((_) async => Success(buildEbook()));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.submit(title: 'Book', filePath: '/tmp/book.pdf');
      cubit.reset();
    },
    skip: 2,
    expect: () => [const UploadState()],
  );
}
