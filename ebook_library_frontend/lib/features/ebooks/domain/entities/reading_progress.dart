import 'package:equatable/equatable.dart';

/// How far the reader has gotten through a given ebook, so the reading
/// screen can resume at the same spot instead of starting over at page 1.
class ReadingProgress extends Equatable {
  const ReadingProgress({
    this.currentPage = 0,
    this.totalPages,
    this.lastPosition = 0.0,
    this.percent = 0.0,
    this.lastOpenedAt,
  });

  final int currentPage;
  final int? totalPages;

  /// 0.0–1.0 fraction, used for continuous-scroll (EPUB-style) readers or
  /// as a fallback when page counts aren't known yet.
  final double lastPosition;

  final double percent;
  final DateTime? lastOpenedAt;

  bool get hasStarted => currentPage > 0 || lastPosition > 0;

  static const empty = ReadingProgress();

  ReadingProgress copyWith({
    int? currentPage,
    int? totalPages,
    double? lastPosition,
    double? percent,
    DateTime? lastOpenedAt,
  }) {
    return ReadingProgress(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastPosition: lastPosition ?? this.lastPosition,
      percent: percent ?? this.percent,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, lastPosition, percent, lastOpenedAt];
}
