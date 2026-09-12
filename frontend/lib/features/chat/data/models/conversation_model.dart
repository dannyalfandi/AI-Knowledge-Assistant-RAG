import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_detail.dart';
import 'message_model.dart';

/// Transport representation of [Conversation] (the list/summary shape, where
/// the message count arrives as `_count.messages`).
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.messageCount,
    required super.createdAt,
    required super.updatedAt,
    super.title,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final createdAt = MessageModel.parseDate(json['createdAt']);

    return ConversationModel(
      id: json['id'] as String,
      title: _parseTitle(json['title']),
      messageCount: _parseMessageCount(json['_count']),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : MessageModel.parseDate(json['updatedAt']),
    );
  }

  static String? _parseTitle(Object? raw) {
    if (raw is! String) return null;
    final title = raw.trim();
    return title.isEmpty ? null : title;
  }

  static int _parseMessageCount(Object? raw) {
    if (raw is Map && raw['messages'] is int) return raw['messages'] as int;
    return 0;
  }
}

/// Transport representation of [ConversationDetail].
class ConversationDetailModel extends ConversationDetail {
  const ConversationDetailModel({
    required super.id,
    required super.messages,
    required super.createdAt,
    required super.updatedAt,
    super.title,
  });

  factory ConversationDetailModel.fromJson(Map<String, dynamic> json) {
    final createdAt = MessageModel.parseDate(json['createdAt']);

    return ConversationDetailModel(
      id: json['id'] as String,
      title: ConversationModel._parseTitle(json['title']),
      messages: MessageModel.listFrom(json['messages']),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : MessageModel.parseDate(json['updatedAt']),
    );
  }
}
