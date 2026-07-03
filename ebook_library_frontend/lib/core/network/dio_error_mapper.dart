import 'package:dio/dio.dart';
import 'package:ebook_library_frontend/core/error/exceptions.dart';

/// Translates whatever Dio throws (timeouts, connection errors, HTTP status
/// codes, malformed responses) into one of our typed [Exception]s so the
/// rest of the app never has to inspect a `DioException` directly.
class DioErrorMapper {
  const DioErrorMapper._();

  static Exception map(Object error) {
    if (error is! DioException) return const UnknownException();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        // Covers "no route to host", DNS failure, connection refused, etc.
        // — i.e. the kind of real-world flaky-network issue that shows up
        // constantly on mobile.
        return const NoInternetException();

      case DioExceptionType.badCertificate:
        return const UnknownException(
            'A secure connection could not be established.');

      case DioExceptionType.cancel:
        return const UnknownException('Request was cancelled.');

      case DioExceptionType.badResponse:
        return _mapStatusCode(error.response);

      case DioExceptionType.unknown:
        // Often a SocketException wrapped by Dio — treat as connectivity.
        return const NoInternetException();
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static Exception _mapStatusCode(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final body = response?.data;

    switch (status) {
      case 404:
        return NotFoundException(_extractMessage(body) ?? 'Not found');
      case 422:
        return ValidationException(_extractErrors(body));
      case >= 500:
        return ServerException(
            _extractMessage(body) ?? 'Server error ($status)');
      case 413:
        return const FileTooLargeException();
      default:
        return UnknownException(
            _extractMessage(body) ?? 'Unexpected error ($status)');
    }
  }

  static String? _extractMessage(dynamic body) {
    if (body is Map && body['error'] is String) return body['error'] as String;
    return null;
  }

  static List<String> _extractErrors(dynamic body) {
    if (body is Map && body['errors'] is List) {
      return (body['errors'] as List).map((e) => e.toString()).toList();
    }
    final single = _extractMessage(body);
    return single != null ? [single] : ['Validation failed'];
  }
}
