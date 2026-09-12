import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/ask_result.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation_detail.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/repositories/chat_repository.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/providers/conversations_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Conversation _conversation(String id, {int messageCount = 0}) {
  return Conversation(
    id: id,
    title: null,
    messageCount: messageCount,
    createdAt: DateTime(2026, 9, 8),
    updatedAt: DateTime(2026, 9, 8),
  );
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({required this.pages});

  /// Keyed by page number, mirroring the backend's 1-based pagination.
  final Map<int, ConversationPage> pages;

  final List<String> deleted = [];
  int createCalls = 0;
  Object? listError;

  @override
  Future<ConversationPage> listConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final error = listError;
    if (error != null) throw error;

    return pages[page] ??
        ConversationPage(
          conversations: const [],
          page: page,
          totalPages: pages.length,
          total: 0,
        );
  }

  @override
  Future<Conversation> createConversation({String? title}) async {
    createCalls++;
    return _conversation('new-conversation');
  }

  @override
  Future<void> deleteConversation(String id) async => deleted.add(id);

  @override
  Future<ConversationDetail> getConversation(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<AskResult> ask({
    required String conversationId,
    required String question,
  }) async {
    throw UnimplementedError();
  }
}

ProviderContainer _container(_FakeChatRepository repository) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ConversationsState> _load(ProviderContainer container) {
  container.listen(conversationsControllerProvider, (_, _) {});
  return container.read(conversationsControllerProvider.future);
}

void main() {
  group('loading', () {
    test('exposes the first page and whether more exist', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a'), _conversation('b')],
            page: 1,
            totalPages: 2,
            total: 3,
          ),
        },
      );
      final container = _container(repository);

      final state = await _load(container);

      expect(state.conversations.map((c) => c.id), ['a', 'b']);
      expect(state.hasMore, isTrue);
    });

    test('a single page reports no more pages', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a')],
            page: 1,
            totalPages: 1,
            total: 1,
          ),
        },
      );
      final container = _container(repository);

      expect((await _load(container)).hasMore, isFalse);
    });

    test('surfaces a backend failure as an error state', () async {
      final repository = _FakeChatRepository(pages: {})
        ..listError = const NetworkException();
      final container = _container(repository);

      await expectLater(_load(container), throwsA(isA<NetworkException>()));
    });
  });

  group('loadMore', () {
    test('appends the next page', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a')],
            page: 1,
            totalPages: 2,
            total: 2,
          ),
          2: ConversationPage(
            conversations: [_conversation('b')],
            page: 2,
            totalPages: 2,
            total: 2,
          ),
        },
      );
      final container = _container(repository);

      await _load(container);
      await container.read(conversationsControllerProvider.notifier).loadMore();

      final state = container.read(conversationsControllerProvider).value!;
      expect(state.conversations.map((c) => c.id), ['a', 'b']);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('does nothing on the last page', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a')],
            page: 1,
            totalPages: 1,
            total: 1,
          ),
        },
      );
      final container = _container(repository);

      await _load(container);
      await container.read(conversationsControllerProvider.notifier).loadMore();

      expect(
        container
            .read(conversationsControllerProvider)
            .value!
            .conversations
            .length,
        1,
      );
    });
  });

  group('mutations', () {
    test('a new conversation goes to the top of the list', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a')],
            page: 1,
            totalPages: 1,
            total: 1,
          ),
        },
      );
      final container = _container(repository);

      await _load(container);
      final created = await container
          .read(conversationsControllerProvider.notifier)
          .createConversation();

      expect(repository.createCalls, 1);
      expect(created.id, 'new-conversation');
      expect(
        container
            .read(conversationsControllerProvider)
            .value!
            .conversations
            .map((c) => c.id),
        ['new-conversation', 'a'],
      );
    });

    test('delete removes the row only after the backend confirms', () async {
      final repository = _FakeChatRepository(
        pages: {
          1: ConversationPage(
            conversations: [_conversation('a'), _conversation('b')],
            page: 1,
            totalPages: 1,
            total: 2,
          ),
        },
      );
      final container = _container(repository);

      await _load(container);
      await container
          .read(conversationsControllerProvider.notifier)
          .delete('a');

      expect(repository.deleted, ['a']);
      expect(
        container
            .read(conversationsControllerProvider)
            .value!
            .conversations
            .map((c) => c.id),
        ['b'],
      );
    });
  });
}
