import '../entities/ask_result.dart';
import '../entities/conversation.dart';
import '../entities/conversation_detail.dart';

/// One page of conversations plus the backend's pagination metadata.
class ConversationPage {
  const ConversationPage({
    required this.conversations,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<Conversation> conversations;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

/// Contract the presentation layer depends on. Every method throws an
/// [AppException] on failure; a conversation belonging to another user comes
/// back as a `NotFoundException`-style 404, not a 403.
abstract interface class ChatRepository {
  /// Creates an empty conversation. A title is optional — the app creates
  /// untitled conversations and lets the first question stand in for one.
  Future<Conversation> createConversation({String? title});

  /// The signed-in user's conversations, newest activity first.
  Future<ConversationPage> listConversations({int page = 1, int limit = 20});

  Future<ConversationDetail> getConversation(String id);

  Future<void> deleteConversation(String id);

  /// Sends a question through the RAG pipeline. Slow by nature (retrieval plus
  /// an LLM call), and answers with 502 when the LLM provider fails. On
  /// failure the backend persists nothing, so retrying the same question does
  /// not duplicate it.
  Future<AskResult> ask({
    required String conversationId,
    required String question,
  });
}
