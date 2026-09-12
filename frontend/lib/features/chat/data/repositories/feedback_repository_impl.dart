import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_feedback.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl({required this.remote});

  final FeedbackRemoteDataSource remote;

  @override
  Future<MessageFeedback> submit({
    required String messageId,
    required FeedbackType type,
    String? comment,
  }) {
    return remote.submit(messageId: messageId, type: type, comment: comment);
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(
    remote: ref.watch(feedbackRemoteDataSourceProvider),
  );
});
