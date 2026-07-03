import 'package:dio/dio.dart';
import 'package:ebook_library_frontend/core/constants/api_constants.dart';

/// Builds the single [Dio] instance used by all data sources.
///
/// Centralizing this means timeouts, base URL, and logging are configured
/// once. Retries for transient failures are handled per-call in the
/// repository layer (see [EbookRepositoryImpl]) rather than here, so retry
/// behavior can differ sensibly between a GET list and a file upload.
class ApiClient {
  ApiClient._(this.dio);

  final Dio dio;

  static ApiClient create({String? baseUrlOverride}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrlOverride ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (_) {}, // swap for a real logger in development if needed
      ),
    );

    return ApiClient._(dio);
  }
}
