import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';

enum UploadStatus { idle, uploading, success, failure }

class UploadState extends Equatable {
  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.uploadedEbook,
    this.failure,
  });

  final UploadStatus status;

  /// 0.0–1.0, driven by Dio's `onSendProgress`.
  final double progress;
  final Ebook? uploadedEbook;
  final Failure? failure;

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    Ebook? uploadedEbook,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      uploadedEbook: uploadedEbook ?? this.uploadedEbook,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, progress, uploadedEbook, failure];
}
