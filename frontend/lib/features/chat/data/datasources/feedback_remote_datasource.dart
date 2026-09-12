import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_provider.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../domain/entities/feedback_type.dart';
import '../models/feedback_model.dart';

/// Talks to the feedback endpoints, which the backend mounts under
/// `/api/messages/:messageId/feedback`.
class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource(this._dio);

  final Dio _dio;

  /// Matches the backend's `upsertFeedbackSchema`.
  static const maxCommentLength = 1000;

  Future<FeedbackModel> submit({
    required String messageId,
    required FeedbackType type,
    String? comment,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/messages/$messageId/feedback',
        data: {
          'type': type.wireValue,
          // Only sent when the caller actually has one: the backend leaves an
          // existing comment alone when the field is absent.
          'comment': ?comment,
        },
      );

      return FeedbackModel.fromJson(_data(response.data));
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

final feedbackRemoteDataSourceProvider = Provider<FeedbackRemoteDataSource>((
  ref,
) {
  return FeedbackRemoteDataSource(ref.watch(dioProvider));
});
