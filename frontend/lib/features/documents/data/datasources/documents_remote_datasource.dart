import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_provider.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../domain/entities/picked_document.dart';
import '../../domain/repositories/documents_repository.dart';
import '../models/document_model.dart';

/// Talks to the `/api/documents` endpoints (all ADMIN-only). The auth
/// interceptor on the shared [Dio] instance attaches the JWT; every `dio`
/// failure is re-thrown as an [AppException] via [mapDioException].
class DocumentsRemoteDataSource {
  DocumentsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DocumentModel>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/documents');
      final data = response.data?['data'];

      if (data is! List) {
        throw const UnknownException('Respons server tidak sesuai format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(DocumentModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<DocumentModel> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/documents/$id');
      return DocumentModel.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// `POST /api/documents` — multipart, field name `file` (must match the
  /// backend's `uploadDocument.single("file")`).
  Future<DocumentModel> upload(
    PickedDocument file, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.name,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/documents',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onProgress,
      );

      return DocumentModel.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// `POST /api/documents/:id/process` — returns 202 as soon as the work is
  /// scheduled, so the response body carries no useful state beyond
  /// "accepted".
  Future<void> process(String id) async {
    try {
      await _dio.post<Map<String, dynamic>>('/documents/$id/process');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// `DELETE /api/documents/:id` — 204 No Content.
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/documents/$id');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const UnknownException('Respons server tidak sesuai format.');
    }
    return data;
  }
}

final documentsRemoteDataSourceProvider = Provider<DocumentsRemoteDataSource>((
  ref,
) {
  return DocumentsRemoteDataSource(ref.watch(dioProvider));
});
