import '../repositories/chat_repository.dart';

/// Deletes a conversation and, by cascade, its messages and citations.
class DeleteConversationUseCase {
  const DeleteConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<void> call(String id) => _repository.deleteConversation(id);
}
