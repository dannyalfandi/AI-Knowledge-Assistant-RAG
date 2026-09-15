import 'message.dart';

/// A conversation together with its full message history, as returned by
/// `GET /api/conversations/:id`.
class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final String? title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
}
