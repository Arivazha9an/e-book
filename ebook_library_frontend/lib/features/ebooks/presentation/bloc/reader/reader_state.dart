import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';

enum ReaderSaveStatus { idle, saving, saved, failed }

/// Deliberately minimal: the PDF viewer widget owns page-rendering state
/// itself (via its own controller). This cubit only tracks the bits the
/// rest of the app cares about — the resume point and whether the latest
/// save succeeded — so a save failure can show a small "not saved" badge
/// without interrupting reading.
class ReaderState extends Equatable {
  const ReaderState({
    required this.ebookId,
    this.initialPage = 0,
    this.saveStatus = ReaderSaveStatus.idle,
    this.failure,
  });

  final int ebookId;
  final int initialPage;
  final ReaderSaveStatus saveStatus;
  final Failure? failure;

  ReaderState copyWith({
    int? initialPage,
    ReaderSaveStatus? saveStatus,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ReaderState(
      ebookId: ebookId,
      initialPage: initialPage ?? this.initialPage,
      saveStatus: saveStatus ?? this.saveStatus,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [ebookId, initialPage, saveStatus, failure];
}
