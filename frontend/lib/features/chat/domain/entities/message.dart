import 'message_feedback.dart';
import 'message_role.dart';
import 'message_source.dart';

/// A single message in a conversation.
class Message {
  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.sources = const [],
    this.myFeedback,
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  /// Citations backing this answer. Always empty for a USER message, and
  /// legitimately empty for an assistant answer that retrieved nothing.
  final List<MessageSource> sources;

  /// The signed-in user's own rating of this answer, loaded together with the
  /// conversation so a reopened chat shows what was already rated. Null when
  /// unrated — and always null for a USER message, which the backend refuses to
  /// accept feedback on.
  final MessageFeedback? myFeedback;

  bool get hasSources => sources.isNotEmpty;

  /// Only assistant answers can be rated.
  bool get canReceiveFeedback => role == MessageRole.assistant;

  Message copyWithFeedback(MessageFeedback? feedback) {
    return Message(
      id: id,
      role: role,
      content: content,
      createdAt: createdAt,
      sources: sources,
      myFeedback: feedback,
    );
  }
}
