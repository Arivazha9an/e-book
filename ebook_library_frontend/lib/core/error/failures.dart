/// All the ways a use case can fail, expressed as a closed set of types so
/// the presentation layer can pattern-match and show the right UI/message
/// instead of a generic "something went wrong".
sealed class Failure {
  const Failure(this.message);

  /// A short, user-friendly message safe to show directly in the UI.
  final String message;
}

/// No internet connection at all (checked via connectivity_plus before the
/// request was even attempted, or a socket-level failure).
class NoInternetFailure extends Failure {
  const NoInternetFailure(
      [String message =
          "You're offline. Check your internet connection and try again."])
      : super(message);
}

/// The request took too long — flaky/slow network, not necessarily "offline".
class TimeoutFailure extends Failure {
  const TimeoutFailure(
      [String message = 'That took too long to respond. Please try again.'])
      : super(message);
}

/// Backend reachable but returned a 5xx.
class ServerFailure extends Failure {
  const ServerFailure(
      [String message =
          'Something went wrong on our end. Please try again shortly.'])
      : super(message);
}

/// 404 — the record (e.g. an ebook) no longer exists.
class NotFoundFailure extends Failure {
  const NotFoundFailure(
      [String message =
          "This item couldn't be found. It may have been deleted."])
      : super(message);
}

/// 422 — validation errors from the backend, kept as a list so forms can
/// show field-specific feedback if needed.
class ValidationFailure extends Failure {
  ValidationFailure(this.errors) : super(_joinErrors(errors));

  final List<String> errors;

  static String _joinErrors(List<String> errors) => errors.isEmpty
      ? 'Please check your input and try again.'
      : errors.join('\n');
}

/// The file the user tried to upload is too large (checked client-side too,
/// so we can fail fast before even starting the upload).
class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure(
      [String message = "That file is too large. The maximum size is 50MB."])
      : super(message);
}

/// Anything unexpected: parsing errors, unknown status codes, etc.
class UnknownFailure extends Failure {
  const UnknownFailure(
      [String message = 'An unexpected error occurred. Please try again.'])
      : super(message);
}
