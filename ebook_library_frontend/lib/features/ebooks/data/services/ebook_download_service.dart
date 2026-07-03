import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ebook_library_frontend/core/error/exceptions.dart';
import 'package:ebook_library_frontend/core/network/dio_error_mapper.dart';

/// Downloads an ebook file to local device storage and opens it with the
/// platform's default viewer/handler. Kept separate from [EbookRepository]
/// since it deals with the filesystem and platform intents rather than
/// pure API data — but still funnels errors through the same
/// [DioErrorMapper] so the UI shows the same friendly messages either way.
class EbookDownloadService {
  EbookDownloadService(this._dio);

  final Dio _dio;

  Future<String> downloadToLocalFile({
    required String url,
    required String suggestedFilename,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$suggestedFilename';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress == null
            ? null
            : (received, total) {
                if (total > 0) onProgress(received / total);
              },
      );

      return savePath;
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  Future<void> openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw UnknownException(result.message);
    }
  }
}
