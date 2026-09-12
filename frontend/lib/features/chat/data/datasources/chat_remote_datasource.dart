import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_provider.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/ask_result_model.dart';
import '../models/conversation_model.dart';

/// Talks to the `/api/conversations` endpoints. Access is scoped per user by
/// the backend, which answers 404 (not 403) for someone else's conversation.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._dio);

  final Dio _dio;

  /// The RAG call runs retrieval plus an LLM completion, which routinely takes
  /// longer than the client's default 20s receive timeout.
  static const askTimeout = Duration(seconds: 60);

  Future<ConversationModel> createConversation({String? title}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/conversations',
        data: {
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        },
      );

      return ConversationModel.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<ConversationPage> listConversations({
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/conversations',
        queryParameters: {'page': page, 'limit': limit},
      );

      final body = response.data;
      final data = body?['data'];

      if (data is! List) {
        throw const UnknownException('Respons server tidak sesuai format.');
      }

      final pagination = body?['pagination'];

      return ConversationPage(
        conversations: data
            .whereType<Map<String, dynamic>>()
            .map(ConversationModel.fromJson)
            .toList(growable: false),
        page: _intFrom(pagination, 'page', page),
        totalPages: _intFrom(pagination, 'totalPages', 1),
        total: _intFrom(pagination, 'total', data.length),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<ConversationDetailModel> getConversation(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/conversations/$id',
      );
      return ConversationDetailModel.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _dio.delete<void>('/conversations/$id');
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<AskResultModel> ask({
    required String conversationId,
    required String question,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/conversations/$conversationId/ask',
        data: {'question': question},
        options: Options(receiveTimeout: askTimeout, sendTimeout: askTimeout),
      );

      return AskResultModel.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  int _intFrom(Object? source, String key, int fallback) {
    if (source is Map && source[key] is num) {
      return (source[key] as num).toInt();
    }
    return fallback;
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const UnknownException('Respons server tidak sesuai format.');
    }
    return data;
  }
}

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(dioProvider));
});
