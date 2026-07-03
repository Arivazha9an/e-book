/// Exceptions live in the data layer (thrown by data sources) and are
/// translated into [Failure]s by the repository before reaching the domain
/// layer. Keeping the two separate means the UI never has to know about
/// HTTP status codes or Dio internals.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found']);
  final String message;
}

class ValidationException implements Exception {
  const ValidationException(this.errors);
  final List<String> errors;
}

class NoInternetException implements Exception {
  const NoInternetException([this.message = 'No internet connection']);
  final String message;
}

class TimeoutException implements Exception {
  const TimeoutException([this.message = 'Request timed out']);
  final String message;
}

class FileTooLargeException implements Exception {
  const FileTooLargeException([this.message = 'File too large']);
  final String message;
}

class UnknownException implements Exception {
  const UnknownException([this.message = 'Unknown error']);
  final String message;
}
