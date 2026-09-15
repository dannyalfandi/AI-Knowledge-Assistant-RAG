import '../entities/message_feedback.dart';
import '../entities/feedback_type.dart';

/// MessageFeedback lives in the chat feature because it is an action on a message
/// rather than a destination of its own, but it keeps its own contract: it is
/// served by a different endpoint family (`/api/messages/...`) and has its own
/// lifecycle, so folding it into `ChatRepository` would blur both.
abstract interface class FeedbackRepository {
  /// Creates or updates the caller's rating of [messageId].
  ///
  /// Omitting [comment] leaves any existing comment untouched — switching from
  /// positive to negative must not erase a note the user wrote earlier. Pass an
  /// explicit empty string to clear it.
  ///
  /// The backend rejects a USER message with 400, so only call this for an
  /// assistant answer.
  Future<MessageFeedback> submit({
    required String messageId,
    required FeedbackType type,
    String? comment,
  });
}
