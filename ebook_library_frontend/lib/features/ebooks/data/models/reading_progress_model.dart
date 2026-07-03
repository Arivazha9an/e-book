import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';

class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    super.currentPage,
    super.totalPages,
    super.lastPosition,
    super.percent,
    super.lastOpenedAt,
  });

  /// Parses the `progress` object embedded in an ebook payload, or the
  /// standalone response from `GET/PATCH .../progress`.
  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt(),
      lastPosition: (json['last_position'] as num?)?.toDouble() ?? 0.0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      lastOpenedAt:
          json['last_opened_at'] != null ? DateTime.tryParse(json['last_opened_at'] as String) : null,
    );
  }

  static const empty = ReadingProgressModel();
}
