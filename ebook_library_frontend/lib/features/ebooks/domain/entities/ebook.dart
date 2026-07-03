import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';

enum EbookFileType { pdf, epub, unknown }

EbookFileType ebookFileTypeFrom(String? raw) {
  switch (raw) {
    case 'pdf':
      return EbookFileType.pdf;
    case 'epub':
      return EbookFileType.epub;
    default:
      return EbookFileType.unknown;
  }
}

/// Core domain entity for a single ebook. This is what the UI layer works
/// with — it has no knowledge of JSON keys or HTTP at all.
class Ebook extends Equatable {
  const Ebook({
    required this.id,
    required this.title,
    this.author,
    this.description,
    required this.fileType,
    this.fileSizeBytes,
    this.originalFilename,
    this.coverUrl,
    required this.downloadUrl,
    required this.createdAt,
    required this.updatedAt,
    this.progress = ReadingProgress.empty,
  });

  final int id;
  final String title;
  final String? author;
  final String? description;
  final EbookFileType fileType;
  final int? fileSizeBytes;
  final String? originalFilename;
  final String? coverUrl;
  final String downloadUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReadingProgress progress;

  String get displayAuthor => author?.trim().isNotEmpty == true ? author! : 'Unknown author';

  String get fileSizeLabel {
    final bytes = fileSizeBytes;
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Ebook copyWith({ReadingProgress? progress}) {
    return Ebook(
      id: id,
      title: title,
      author: author,
      description: description,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      originalFilename: originalFilename,
      coverUrl: coverUrl,
      downloadUrl: downloadUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        description,
        fileType,
        fileSizeBytes,
        originalFilename,
        coverUrl,
        downloadUrl,
        createdAt,
        updatedAt,
        progress,
      ];
}
