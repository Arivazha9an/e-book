import 'package:ebook_library_frontend/features/ebooks/data/models/reading_progress_model.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

/// Maps 1:1 onto the JSON shape documented in the backend's
/// `docs/API_DOCUMENTATION.md` (`EbookSerializer#as_json`).
class EbookModel extends Ebook {
  const EbookModel({
    required super.id,
    required super.title,
    super.author,
    super.description,
    required super.fileType,
    super.fileSizeBytes,
    super.originalFilename,
    super.coverUrl,
    required super.downloadUrl,
    required super.createdAt,
    required super.updatedAt,
    super.progress,
  });

  factory EbookModel.fromJson(Map<String, dynamic> json) {
    return EbookModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      author: json['author'] as String?,
      description: json['description'] as String?,
      fileType: ebookFileTypeFrom(json['file_type'] as String?),
      fileSizeBytes: (json['file_size'] as num?)?.toInt(),
      originalFilename: json['original_filename'] as String?,
      coverUrl: json['cover_url'] as String?,
      downloadUrl: json['download_url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      progress: json['progress'] is Map<String, dynamic>
          ? ReadingProgressModel.fromJson(json['progress'] as Map<String, dynamic>)
          : ReadingProgressModel.empty,
    );
  }
}
