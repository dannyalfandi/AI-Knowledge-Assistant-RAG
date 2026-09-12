import '../../domain/entities/message_feedback.dart';
import '../../domain/entities/feedback_type.dart';
import 'message_model.dart';

/// Transport representation of [MessageFeedback].
///
/// The same shape arrives from `POST /api/messages/:id/feedback` and, as
/// `myFeedback`, from `GET /api/conversations/:id`.
class FeedbackModel extends MessageFeedback {
  const FeedbackModel({
    required super.id,
    required super.type,
    required super.createdAt,
    required super.updatedAt,
    super.comment,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    final createdAt = MessageModel.parseDate(json['createdAt']);

    return FeedbackModel(
      id: json['id'] as String? ?? '',
      type: parseType(json['type']),
      comment: _parseComment(json['comment']),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : MessageModel.parseDate(json['updatedAt']),
    );
  }

  /// Returns null for a message the user has not rated.
  static FeedbackModel? tryFrom(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return FeedbackModel.fromJson(raw);
  }

  /// An unrecognised type falls back to negative rather than throwing: the
  /// backend enum only has two values, and guessing "positive" would overstate
  /// the user's opinion.
  static FeedbackType parseType(Object? raw) {
    return raw == 'POSITIVE' ? FeedbackType.positive : FeedbackType.negative;
  }

  static String? _parseComment(Object? raw) {
    if (raw is! String) return null;
    final comment = raw.trim();
    return comment.isEmpty ? null : comment;
  }
}
