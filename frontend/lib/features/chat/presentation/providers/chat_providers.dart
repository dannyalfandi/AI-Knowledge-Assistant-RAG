import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/usecases/ask_question_usecase.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/delete_conversation_usecase.dart';
import '../../domain/usecases/get_conversation_usecase.dart';
import '../../domain/usecases/list_conversations_usecase.dart';
import '../../domain/usecases/submit_feedback_usecase.dart';

/// Use-case wiring, kept separate from the controllers (same split as
/// `auth_providers.dart` and `documents_providers.dart`).
final createConversationUseCaseProvider = Provider<CreateConversationUseCase>((
  ref,
) {
  return CreateConversationUseCase(ref.watch(chatRepositoryProvider));
});

final listConversationsUseCaseProvider = Provider<ListConversationsUseCase>((
  ref,
) {
  return ListConversationsUseCase(ref.watch(chatRepositoryProvider));
});

final getConversationUseCaseProvider = Provider<GetConversationUseCase>((ref) {
  return GetConversationUseCase(ref.watch(chatRepositoryProvider));
});

final deleteConversationUseCaseProvider = Provider<DeleteConversationUseCase>((
  ref,
) {
  return DeleteConversationUseCase(ref.watch(chatRepositoryProvider));
});

final askQuestionUseCaseProvider = Provider<AskQuestionUseCase>((ref) {
  return AskQuestionUseCase(ref.watch(chatRepositoryProvider));
});

final submitFeedbackUseCaseProvider = Provider<SubmitFeedbackUseCase>((ref) {
  return SubmitFeedbackUseCase(ref.watch(feedbackRepositoryProvider));
});

/// How many conversations one list page holds. Matches the backend default.
const conversationsPageSize = 20;
