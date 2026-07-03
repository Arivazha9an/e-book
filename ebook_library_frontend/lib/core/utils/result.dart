import 'package:ebook_library_frontend/core/error/failures.dart';

/// A minimal `Either`-style result type so use cases never throw across
/// layer boundaries — callers are forced (via the sealed type + switch) to
/// handle both the success and failure paths explicitly.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Error<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
