import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ebook_library_frontend/core/constants/api_constants.dart';
import 'package:ebook_library_frontend/core/error/exceptions.dart';
import 'package:ebook_library_frontend/core/network/dio_error_mapper.dart';
import 'package:ebook_library_frontend/features/ebooks/data/models/ebook_model.dart';
import 'package:ebook_library_frontend/features/ebooks/data/models/paginated_response.dart';
import 'package:ebook_library_frontend/features/ebooks/data/models/reading_progress_model.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

abstract class EbookRemoteDataSource {
  Future<PaginatedEbooksResponse> getEbooks({
    required int page,
    required int perPage,
    required EbookSort sort,
    String? fileType,
  });

  Future<PaginatedEbooksResponse> searchEbooks({
    required String query,
    required int page,
    required int perPage,
    required EbookSort sort,
    String? fileType,
  });

  Future<EbookModel> getEbook(int id);

  Future<EbookModel> uploadEbook({
    required String title,
    String? author,
    String? description,
    required String filePath,
    String? coverImagePath,
    void Function(double progress)? onSendProgress,
  });

  Future<void> deleteEbook(int id);

  Future<String> getDownloadUrl(int id);

  Future<ReadingProgressModel> getProgress(int id);

  Future<ReadingProgressModel> updateProgress({
    required int id,
    int? currentPage,
    int? totalPages,
    double? lastPosition,
  });
}

class EbookRemoteDataSourceImpl implements EbookRemoteDataSource {
  EbookRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  String _sortParam(EbookSort sort) {
    switch (sort) {
      case EbookSort.recent:
        return 'recent';
      case EbookSort.oldest:
        return 'oldest';
      case EbookSort.title:
        return 'title';
      case EbookSort.author:
        return 'author';
      case EbookSort.recentlyRead:
        return 'recently_read';
    }
  }

  @override
  Future<PaginatedEbooksResponse> getEbooks({
    required int page,
    required int perPage,
    required EbookSort sort,
    String? fileType,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.ebooks,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': _sortParam(sort),
          if (fileType != null) 'file_type': fileType,
        },
      );
      return PaginatedEbooksResponse.fromJson(response.data!);
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<PaginatedEbooksResponse> searchEbooks({
    required String query,
    required int page,
    required int perPage,
    required EbookSort sort,
    String? fileType,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.search,
        queryParameters: {
          'q': query,
          'page': page,
          'per_page': perPage,
          'sort': _sortParam(sort),
          if (fileType != null) 'file_type': fileType,
        },
      );
      return PaginatedEbooksResponse.fromJson(response.data!);
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<EbookModel> getEbook(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.ebook(id));
      return EbookModel.fromJson(response.data!);
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<EbookModel> uploadEbook({
    required String title,
    String? author,
    String? description,
    required String filePath,
    String? coverImagePath,
    void Function(double progress)? onSendProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      if (fileSize > ApiConstants.maxUploadBytes) {
        throw const FileTooLargeException();
      }

      final formData = FormData.fromMap({
        'ebook[title]': title,
        if (author != null && author.isNotEmpty) 'ebook[author]': author,
        if (description != null && description.isNotEmpty) 'ebook[description]': description,
        'ebook[file]': await MultipartFile.fromFile(filePath),
        if (coverImagePath != null)
          'ebook[cover_image]': await MultipartFile.fromFile(coverImagePath),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.ebooks,
        data: formData,
        onSendProgress: onSendProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onSendProgress(sent / total);
              },
      );
      return EbookModel.fromJson(response.data!);
    } on FileTooLargeException {
      rethrow;
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<void> deleteEbook(int id) async {
    try {
      await _dio.delete<void>(ApiConstants.ebook(id));
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<String> getDownloadUrl(int id) async {
    // The backend responds with a 302 redirect to a signed blob URL. We
    // don't need to follow it ourselves — returning the endpoint URL lets
    // the platform downloader / url_launcher follow the redirect natively.
    return '${ApiConstants.baseUrl}${ApiConstants.download(id)}';
  }

  @override
  Future<ReadingProgressModel> getProgress(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.progress(id));
      return ReadingProgressModel.fromJson(response.data!);
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }

  @override
  Future<ReadingProgressModel> updateProgress({
    required int id,
    int? currentPage,
    int? totalPages,
    double? lastPosition,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.progress(id),
        data: {
          if (currentPage != null) 'current_page': currentPage,
          if (totalPages != null) 'total_pages': totalPages,
          if (lastPosition != null) 'last_position': lastPosition,
        },
      );
      return ReadingProgressModel.fromJson(response.data!);
    } catch (e) {
      throw DioErrorMapper.map(e);
    }
  }
}
