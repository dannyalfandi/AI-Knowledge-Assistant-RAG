import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ask_result.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_detail.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required this.remote});

  final ChatRemoteDataSource remote;

  @override
  Future<Conversation> createConversation({String? title}) {
    return remote.createConversation(title: title);
  }

  @override
  Future<ConversationPage> listConversations({int page = 1, int limit = 20}) {
    return remote.listConversations(page: page, limit: limit);
  }

  @override
  Future<ConversationDetail> getConversation(String id) {
    return remote.getConversation(id);
  }

  @override
  Future<void> deleteConversation(String id) => remote.deleteConversation(id);

  @override
  Future<AskResult> ask({
    required String conversationId,
    required String question,
  }) {
    return remote.ask(conversationId: conversationId, question: question);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(remote: ref.watch(chatRemoteDataSourceProvider));
});
