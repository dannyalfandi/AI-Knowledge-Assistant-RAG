import '../../domain/entities/message.dart';
import '../../domain/entities/message_role.dart';
import 'feedback_model.dart';
import 'message_source_model.dart';

/// Transport representation of [Message].
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.role,
    required super.content,
    required super.createdAt,
    super.sources,
    super.myFeedback,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      role: _parseRole(json['role']),
      content: json['content'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      sources: MessageSourceModel.listFrom(json['sources']),
      myFeedback: FeedbackModel.tryFrom(json['myFeedback']),
    );
  }

  static MessageRole _parseRole(Object? raw) {
    return switch (raw) {
      'USER' => MessageRole.user,
      'ASSISTANT' => MessageRole.assistant,
      _ => MessageRole.unknown,
    };
  }

  static DateTime parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static List<Message> listFrom(Object? raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromJson)
        .toList(growable: false);
  }
}
