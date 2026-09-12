import '../repositories/chat_repository.dart';

/// Loads one page of the user's conversations.
class ListConversationsUseCase {
  const ListConversationsUseCase(this._repository);

  final ChatRepository _repository;

  Future<ConversationPage> call({int page = 1, int limit = 20}) {
    return _repository.listConversations(page: page, limit: limit);
  }
}
