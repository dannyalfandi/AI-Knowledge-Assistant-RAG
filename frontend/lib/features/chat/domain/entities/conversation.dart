/// A conversation as it appears in the list — metadata only, no messages.
class Conversation {
  const Conversation({
    required this.id,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;

  /// Null until a title is set; the backend accepts creating one without it.
  final String? title;

  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}
