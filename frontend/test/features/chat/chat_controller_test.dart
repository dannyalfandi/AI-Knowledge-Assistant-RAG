import 'dart:async';

import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/ask_result.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation_detail.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_role.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_source.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/repositories/chat_repository.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/providers/chat_controller.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/providers/chat_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _conversationId = 'c1';
const _otherConversationId = 'c2';

Message _message(String id, MessageRole role, String content) {
  return Message(
    id: id,
    role: role,
    content: content,
    createdAt: DateTime(2026, 9, 8),
    sources: role == MessageRole.assistant
        ? const [
            MessageSource(
              documentChunkId: 'chunk-1',
              documentId: 'doc-1',
              documentName: 'Refund Policy.pdf',
              chunkIndex: 5,
              content: 'Refund maksimal 7 hari.',
              similarityScore: 0.81,
              pageNumber: 4,
            ),
          ]
        : const [],
  );
}

class _FakeChatRepository implements ChatRepository {
  final Map<String, List<Message>> history = {
    _conversationId: <Message>[],
    _otherConversationId: <Message>[],
  };

  int askCalls = 0;
  Object? askError;
  Object? getError;

  /// When set, `ask` waits on this before answering, so a test can observe the
  /// in-flight state.
  Completer<void>? askGate;

  @override
  Future<Conversation> createConversation({String? title}) async {
    throw UnimplementedError();
  }

  @override
  Future<ConversationPage> listConversations({
    int page = 1,
    int limit = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ConversationDetail> getConversation(String id) async {
    final error = getError;
    if (error != null) throw error;

    return ConversationDetail(
      id: id,
      title: null,
      messages: List.of(history[id] ?? const []),
      createdAt: DateTime(2026, 9, 8),
      updatedAt: DateTime(2026, 9, 8),
    );
  }

  @override
  Future<void> deleteConversation(String id) async => history.remove(id);

  @override
  Future<AskResult> ask({
    required String conversationId,
    required String question,
  }) async {
    askCalls++;
    await askGate?.future;

    final error = askError;
    if (error != null) throw error;

    final userMessage = _message('u$askCalls', MessageRole.user, question);
    final assistantMessage = _message(
      'a$askCalls',
      MessageRole.assistant,
      'Jawaban untuk: $question',
    );

    history[conversationId] = [
      ...?history[conversationId],
      userMessage,
      assistantMessage,
    ];

    return AskResult(
      userMessage: userMessage,
      assistantMessage: assistantMessage,
    );
  }
}

ProviderContainer _container(_FakeChatRepository repository) {
  final container = ProviderContainer(
    overrides: [chatRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Loads a conversation and keeps a listener for the rest of the test: the
/// provider is auto-dispose and would otherwise be torn down immediately.
Future<ChatState> _load(ProviderContainer container, String id) {
  container.listen(chatControllerProvider(id), (_, _) {});
  return container.read(chatControllerProvider(id).future);
}

void main() {
  group('ask', () {
    test(
      'appends the stored question and answer, then clears pending',
      () async {
        final repository = _FakeChatRepository();
        final container = _container(repository);

        await _load(container, _conversationId);
        await container
            .read(chatControllerProvider(_conversationId).notifier)
            .ask('berapa lama refund?');

        final state = container
            .read(chatControllerProvider(_conversationId))
            .value!;

        expect(state.pending, isNull);
        expect(state.messages.map((m) => m.role), [
          MessageRole.user,
          MessageRole.assistant,
        ]);
        expect(state.messages.last.sources, hasLength(1));
      },
    );

    test(
      'shows the question as pending while the answer is in flight',
      () async {
        final repository = _FakeChatRepository()..askGate = Completer<void>();
        final container = _container(repository);

        await _load(container, _conversationId);
        final notifier = container.read(
          chatControllerProvider(_conversationId).notifier,
        );

        final pendingAsk = notifier.ask('berapa lama refund?');
        await Future<void>.delayed(Duration.zero);

        final inFlight = container
            .read(chatControllerProvider(_conversationId))
            .value!;
        expect(inFlight.isAwaitingAnswer, isTrue);
        expect(inFlight.pending!.question, 'berapa lama refund?');

        repository.askGate!.complete();
        await pendingAsk;

        expect(
          container
              .read(chatControllerProvider(_conversationId))
              .value!
              .pending,
          isNull,
        );
      },
    );

    test(
      'a second question is ignored while one is still being answered',
      () async {
        final repository = _FakeChatRepository()..askGate = Completer<void>();
        final container = _container(repository);

        await _load(container, _conversationId);
        final notifier = container.read(
          chatControllerProvider(_conversationId).notifier,
        );

        final first = notifier.ask('pertanyaan pertama');
        await Future<void>.delayed(Duration.zero);
        await notifier.ask('pertanyaan kedua');

        expect(repository.askCalls, 1);

        repository.askGate!.complete();
        await first;
      },
    );

    test('an empty or whitespace-only question is not sent', () async {
      final repository = _FakeChatRepository();
      final container = _container(repository);

      await _load(container, _conversationId);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .ask('   ');

      expect(repository.askCalls, 0);
    });

    test('waiting in one conversation leaves another free to ask', () async {
      final repository = _FakeChatRepository()..askGate = Completer<void>();
      final container = _container(repository);

      await _load(container, _conversationId);
      await _load(container, _otherConversationId);

      final blocked = container
          .read(chatControllerProvider(_conversationId).notifier)
          .ask('pertanyaan di percakapan pertama');
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(chatControllerProvider(_conversationId))
            .value!
            .isAwaitingAnswer,
        isTrue,
      );
      // The second conversation has its own state and stays usable.
      expect(
        container
            .read(chatControllerProvider(_otherConversationId))
            .value!
            .isAwaitingAnswer,
        isFalse,
      );

      repository.askGate!.complete();
      await blocked;
    });
  });

  group('failure handling', () {
    test(
      'keeps the question visible with the backend message on 502',
      () async {
        final repository = _FakeChatRepository()
          ..askError = const ApiException(
            'Gagal mendapatkan jawaban dari LLM',
            statusCode: 502,
          );
        final container = _container(repository);

        await _load(container, _conversationId);
        await container
            .read(chatControllerProvider(_conversationId).notifier)
            .ask('berapa lama refund?');

        final state = container
            .read(chatControllerProvider(_conversationId))
            .value!;

        expect(state.messages, isEmpty);
        expect(state.pending, isNotNull);
        expect(state.pending!.hasFailed, isTrue);
        expect(state.pending!.question, 'berapa lama refund?');
        expect(
          state.pending!.errorMessage,
          'Gagal mendapatkan jawaban dari LLM',
        );
        expect(state.isAwaitingAnswer, isFalse);
      },
    );

    test('retry re-sends the same question and succeeds', () async {
      final repository = _FakeChatRepository()
        ..askError = const NetworkException();
      final container = _container(repository);

      await _load(container, _conversationId);
      final notifier = container.read(
        chatControllerProvider(_conversationId).notifier,
      );

      await notifier.ask('berapa lama refund?');
      expect(
        container
            .read(chatControllerProvider(_conversationId))
            .value!
            .pending!
            .hasFailed,
        isTrue,
      );

      repository.askError = null;
      await notifier.retryPending();

      final state = container
          .read(chatControllerProvider(_conversationId))
          .value!;
      expect(state.pending, isNull);
      expect(state.messages.first.content, 'berapa lama refund?');
      // One failed attempt plus one retry, and only the retry stored anything.
      expect(repository.askCalls, 2);
      expect(state.messages, hasLength(2));
    });

    test('dismiss drops the failed question without re-sending', () async {
      final repository = _FakeChatRepository()
        ..askError = const NetworkException();
      final container = _container(repository);

      await _load(container, _conversationId);
      final notifier = container.read(
        chatControllerProvider(_conversationId).notifier,
      );

      await notifier.ask('berapa lama refund?');
      notifier.dismissPending();

      final state = container
          .read(chatControllerProvider(_conversationId))
          .value!;
      expect(state.pending, isNull);
      expect(state.messages, isEmpty);
      expect(repository.askCalls, 1);
    });
  });

  group('loading', () {
    test(
      "surfaces the 404 for a conversation that is not the user's",
      () async {
        final repository = _FakeChatRepository()
          ..getError = const ApiException(
            'Conversation not found',
            statusCode: 404,
          );
        final container = _container(repository);

        await expectLater(
          _load(container, _conversationId),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('a conversation with no messages loads as an empty chat', () async {
      final repository = _FakeChatRepository();
      final container = _container(repository);

      final state = await _load(container, _conversationId);

      expect(state.messages, isEmpty);
      expect(state.isEmpty, isTrue);
      expect(state.isAwaitingAnswer, isFalse);
    });

    test('reloading keeps an in-flight question on screen', () async {
      final repository = _FakeChatRepository()..askGate = Completer<void>();
      final container = _container(repository);

      await _load(container, _conversationId);
      final notifier = container.read(
        chatControllerProvider(_conversationId).notifier,
      );

      final pendingAsk = notifier.ask('berapa lama refund?');
      await Future<void>.delayed(Duration.zero);

      await notifier.refresh();

      // The question is client-only until the answer arrives; a rebuild must
      // not make it disappear.
      final state = container
          .read(chatControllerProvider(_conversationId))
          .value!;
      expect(state.pending?.question, 'berapa lama refund?');

      repository.askGate!.complete();
      await pendingAsk;
    });
  });
}
