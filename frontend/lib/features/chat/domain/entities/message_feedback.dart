import 'feedback_type.dart';

/// The signed-in user's rating of one assistant answer.
///
/// The backend keeps at most one row per (user, message) and only upserts it —
/// there is no delete endpoint, so a rating can be changed but not withdrawn.
class MessageFeedback {
  const MessageFeedback({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
  });

  final String id;
  final FeedbackType type;

  /// Optional free-text note, up to 1000 characters on the backend.
  final String? comment;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasComment => comment != null && comment!.isNotEmpty;
}
