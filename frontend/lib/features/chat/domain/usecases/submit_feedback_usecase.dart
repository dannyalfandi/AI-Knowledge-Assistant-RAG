import '../entities/message_feedback.dart';
import '../entities/feedback_type.dart';
import '../repositories/feedback_repository.dart';

/// Rates an assistant answer, optionally with a comment.
class SubmitFeedbackUseCase {
  const SubmitFeedbackUseCase(this._repository);

  final FeedbackRepository _repository;

  Future<MessageFeedback> call({
    required String messageId,
    required FeedbackType type,
    String? comment,
  }) {
    return _repository.submit(
      messageId: messageId,
      type: type,
      comment: comment,
    );
  }
}
