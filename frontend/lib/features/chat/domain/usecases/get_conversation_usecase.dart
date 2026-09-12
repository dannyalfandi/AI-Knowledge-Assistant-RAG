import '../entities/conversation_detail.dart';
import '../repositories/chat_repository.dart';

/// Loads a conversation with its full message history and citations.
class GetConversationUseCase {
  const GetConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<ConversationDetail> call(String id) => _repository.getConversation(id);
}
