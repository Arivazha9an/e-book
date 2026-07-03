import 'package:ebook_library_frontend/core/error/exceptions.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/network/network_info.dart';
import 'package:ebook_library_frontend/core/utils/result.dart';
import 'package:ebook_library_frontend/features/ebooks/data/datasources/ebook_remote_data_source.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/paginated_result.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/reading_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

/// Bridges the domain layer to the remote data source.
///
/// Responsibilities that live here (and nowhere else):
/// - Checking connectivity *before* firing a request, so a known-offline
///   device fails fast with a clear message instead of waiting out a
///   timeout.
/// - Converting data-layer [Exception]s into domain [Failure]s.
/// - A small bounded retry for read-only (GET) calls that hit a transient
///   timeout — real networks (especially mobile) frequently have brief
///   blips that succeed on a second attempt, and retrying a GET is safe
///   since it has no side effects. Writes (upload/delete/update progress)
///   are never auto-retried, to avoid duplicating an action.
class EbookRepositoryImpl implements EbookRepository {
  EbookRepositoryImpl({
    required EbookRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _networkInfo = networkInfo;

  final EbookRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  static const _maxReadRetries = 1;

  @override
  Future<Result<PaginatedResult<Ebook>>> getEbooks({
    required int page,
    int perPage = 20,
    EbookSort sort = EbookSort.recent,
    String? fileType,
  }) {
    return _guard(() async {
      final response = await _withRetry(
        () => _remote.getEbooks(page: page, perPage: perPage, sort: sort, fileType: fileType),
      );
      return response.toEntity();
    });
  }

  @override
  Future<Result<PaginatedResult<Ebook>>> searchEbooks({
    required String query,
    required int page,
    int perPage = 20,
    EbookSort sort = EbookSort.recent,
    String? fileType,
  }) {
    return _guard(() async {
      final response = await _withRetry(
        () => _remote.searchEbooks(
          query: query,
          page: page,
          perPage: perPage,
          sort: sort,
          fileType: fileType,
        ),
      );
      return response.toEntity();
    });
  }

  @override
  Future<Result<Ebook>> getEbook(int id) {
    return _guard(() => _withRetry(() => _remote.getEbook(id)));
  }

  @override
  Future<Result<Ebook>> uploadEbook({
    required String title,
    String? author,
    String? description,
    required String filePath,
    String? coverImagePath,
    void Function(double progress)? onSendProgress,
  }) {
    return _guard(() {
      return _remote.uploadEbook(
        title: title,
        author: author,
        description: description,
        filePath: filePath,
        coverImagePath: coverImagePath,
        onSendProgress: onSendProgress,
      );
    });
  }

  @override
  Future<Result<void>> deleteEbook(int id) {
    return _guard(() => _remote.deleteEbook(id));
  }

  @override
  Future<Result<String>> getDownloadUrl(int id) {
    return _guard(() => _remote.getDownloadUrl(id));
  }

  @override
  Future<Result<ReadingProgress>> getProgress(int id) {
    return _guard(() => _withRetry(() => _remote.getProgress(id)));
  }

  @override
  Future<Result<ReadingProgress>> updateProgress({
    required int id,
    int? currentPage,
    int? totalPages,
    double? lastPosition,
  }) {
    return _guard(() {
      return _remote.updateProgress(
        id: id,
        currentPage: currentPage,
        totalPages: totalPages,
        lastPosition: lastPosition,
      );
    });
  }

  /// Checks connectivity, runs [action], and converts any thrown exception
  /// into a typed [Failure]. Every public method funnels through this so
  /// error handling is consistent everywhere.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NoInternetFailure());
    }

    try {
      final data = await action();
      return Success(data);
    } on NoInternetException catch (e) {
      return Error(NoInternetFailure(e.message));
    } on TimeoutException catch (e) {
      return Error(TimeoutFailure(e.message));
    } on NotFoundException catch (e) {
      return Error(NotFoundFailure(e.message));
    } on ValidationException catch (e) {
      return Error(ValidationFailure(e.errors));
    } on FileTooLargeException catch (e) {
      return Error(FileTooLargeFailure(e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  /// Retries a read-only call once if it fails with a timeout — most
  /// "flaky network" issues on mobile resolve themselves within a second
  /// or two. Any other failure type is not retried (e.g. offline or 404
  /// won't magically succeed on a second attempt).
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on TimeoutException {
        attempt++;
        if (attempt > _maxReadRetries) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
  }
}
