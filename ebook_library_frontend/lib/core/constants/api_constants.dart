/// Central place for the backend base URL and endpoint paths.
///
/// This mirrors exactly what's documented in the backend's
/// `docs/API_DOCUMENTATION.md`. If the backend's routes change, this is the
/// only file that should need updating on the frontend.
class ApiConstants {
  const ApiConstants._();

  /// Android emulator's alias for the host machine's localhost.
  /// - iOS simulator / physical device on same network: use your machine's
  ///   LAN IP instead, e.g. `http://192.168.1.23:3000`.
  /// - Physical device: backend must be reachable on the network (or use a
  ///   tunnel like ngrok) — localhost on the phone is NOT the same as your
  ///   dev machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.3:3000',
  );

  static const String apiPrefix = '/api/v1';

  static const String health = '$apiPrefix/health';
  static const String ebooks = '$apiPrefix/ebooks';
  static const String search = '$apiPrefix/ebooks/search';

  static String ebook(int id) => '$apiPrefix/ebooks/$id';
  static String download(int id) => '$apiPrefix/ebooks/$id/download';
  static String progress(int id) => '$apiPrefix/ebooks/$id/progress';

  static const int defaultPerPage = 20;
  static const int maxUploadBytes =
      50 * 1024 * 1024; // 50MB, mirrors backend limit

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout =
      Duration(seconds: 60); // uploads can be slow
}
