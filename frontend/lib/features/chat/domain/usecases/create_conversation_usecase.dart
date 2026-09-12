import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Starts a new, empty conversation. The app calls this when the user taps
/// "New Chat", before any question is typed.
class CreateConversationUseCase {
  const CreateConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<Conversation> call({String? title}) {
    return _repository.createConversation(title: title);
  }
}
