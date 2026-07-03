import 'package:ebook_library_frontend/core/usecase/usecase.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

class UploadEbookParams {
  const UploadEbookParams({
    required this.title,
    this.author,
    this.description,
    required this.filePath,
    this.coverImagePath,
    this.onSendProgress,
  });

  final String title;
  final String? author;
  final String? description;
  final String filePath;
  final String? coverImagePath;
  final void Function(double progress)? onSendProgress;
}

class UploadEbook implements UseCase<Ebook, UploadEbookParams> {
  UploadEbook(this._repository);

  final EbookRepository _repository;

  @override
  Future<Result<Ebook>> call(UploadEbookParams params) {
    return _repository.uploadEbook(
      title: params.title,
      author: params.author,
      description: params.description,
      filePath: params.filePath,
      coverImagePath: params.coverImagePath,
      onSendProgress: params.onSendProgress,
    );
  }
}
