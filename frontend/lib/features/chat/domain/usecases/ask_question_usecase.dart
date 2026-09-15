import '../entities/ask_result.dart';
import '../repositories/chat_repository.dart';

/// Asks a grounded question inside a conversation and returns both the stored
/// question and the answer with its citations.
class AskQuestionUseCase {
  const AskQuestionUseCase(this._repository);

  final ChatRepository _repository;

  Future<AskResult> call({
    required String conversationId,
    required String question,
  }) {
    return _repository.ask(conversationId: conversationId, question: question);
  }
}
