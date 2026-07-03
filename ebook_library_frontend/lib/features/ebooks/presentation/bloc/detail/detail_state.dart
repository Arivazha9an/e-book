import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

enum DetailStatus { loading, success, failure }
enum DetailAction { none, deleting, preparingDownload }

class DetailState extends Equatable {
  const DetailState({
    this.status = DetailStatus.loading,
    this.ebook,
    this.failure,
    this.action = DetailAction.none,
    this.deleted = false,
  });

  final DetailStatus status;
  final Ebook? ebook;
  final Failure? failure;
  final DetailAction action;

  /// Set to true once deletion succeeds, so the page can pop itself.
  final bool deleted;

  DetailState copyWith({
    DetailStatus? status,
    Ebook? ebook,
    Failure? failure,
    bool clearFailure = false,
    DetailAction? action,
    bool? deleted,
  }) {
    return DetailState(
      status: status ?? this.status,
      ebook: ebook ?? this.ebook,
      failure: clearFailure ? null : (failure ?? this.failure),
      action: action ?? this.action,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props => [status, ebook, failure, action, deleted];
}
