import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/models/feedback_model.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/models/message_model.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/repositories/feedback_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/ask_result.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/conversation_detail.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_feedback.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/feedback_type.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_role.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/repositories/chat_repository.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/repositories/feedback_repository.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/providers/chat_controller.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/providers/chat_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _conversationId = 'c1';
const _assistantMessageId = 'm2';
const _userMessageId = 'm1';

Message _message(String id, MessageRole role, {MessageFeedback? myFeedback}) {
  return Message(
    id: id,
    role: role,
    content: role == MessageRole.user ? 'q' : 'a',
    createdAt: DateTime(2026, 9, 8),
    myFeedback: myFeedback,
  );
}

MessageFeedback _feedback(FeedbackType type, {String? comment}) {
  return MessageFeedback(
    id: 'fb-1',
    type: type,
    comment: comment,
    createdAt: DateTime(2026, 9, 8),
    updatedAt: DateTime(2026, 9, 8),
  );
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({required this.messages});

  final List<Message> messages;

  @override
  Future<ConversationDetail> getConversation(String id) async {
    return ConversationDetail(
      id: id,
      title: null,
      messages: List.of(messages),
      createdAt: DateTime(2026, 9, 8),
      updatedAt: DateTime(2026, 9, 8),
    );
  }

  @override
  Future<Conversation> createConversation({String? title}) async =>
      throw UnimplementedError();

  @override
  Future<ConversationPage> listConversations({
    int page = 1,
    int limit = 20,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteConversation(String id) async =>
      throw UnimplementedError();

  @override
  Future<AskResult> ask({
    required String conversationId,
    required String question,
  }) async => throw UnimplementedError();
}

class _FakeFeedbackRepository implements FeedbackRepository {
  int calls = 0;
  FeedbackType? lastType;
  String? lastComment;
  bool lastCommentWasSent = false;
  Object? error;

  @override
  Future<MessageFeedback> submit({
    required String messageId,
    required FeedbackType type,
    String? comment,
  }) async {
    calls++;
    lastType = type;
    lastComment = comment;
    lastCommentWasSent = comment != null;

    final failure = error;
    if (failure != null) throw failure;

    return _feedback(type, comment: comment);
  }
}

ProviderContainer _container({
  required _FakeChatRepository chat,
  required _FakeFeedbackRepository feedback,
}) {
  final container = ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(chat),
      feedbackRepositoryProvider.overrideWithValue(feedback),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ChatState> _load(ProviderContainer container) {
  container.listen(chatControllerProvider(_conversationId), (_, _) {});
  return container.read(chatControllerProvider(_conversationId).future);
}

Message _messageById(ProviderContainer container, String id) {
  return container
      .read(chatControllerProvider(_conversationId))
      .value!
      .messages
      .firstWhere((message) => message.id == id);
}

void main() {
  group('FeedbackModel', () {
    test('parses the stored feedback that rides along with a message', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'a',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'myFeedback': {
          'id': 'fb-1',
          'type': 'NEGATIVE',
          'comment': 'kurang lengkap',
          'createdAt': '2026-09-08T00:00:00.000Z',
          'updatedAt': '2026-09-08T00:01:00.000Z',
        },
      });

      expect(message.myFeedback, isNotNull);
      expect(message.myFeedback!.type, FeedbackType.negative);
      expect(message.myFeedback!.comment, 'kurang lengkap');
      expect(message.myFeedback!.hasComment, isTrue);
    });

    test('an unrated message has no feedback', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'a',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'myFeedback': null,
      });

      expect(message.myFeedback, isNull);
    });

    test('a null comment is not reported as a comment', () {
      final feedback = FeedbackModel.fromJson({
        'id': 'fb-1',
        'type': 'POSITIVE',
        'comment': null,
        'createdAt': '2026-09-08T00:00:00.000Z',
        'updatedAt': '2026-09-08T00:00:00.000Z',
      });

      expect(feedback.hasComment, isFalse);
    });

    test('the wire value matches the backend enum', () {
      expect(FeedbackType.positive.wireValue, 'POSITIVE');
      expect(FeedbackType.negative.wireValue, 'NEGATIVE');
    });
  });

  group('submitFeedback', () {
    test('sets the rating on an unrated assistant answer', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(_userMessageId, MessageRole.user),
          _message(_assistantMessageId, MessageRole.assistant),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(_assistantMessageId, type: FeedbackType.positive);

      expect(feedback.calls, 1);
      expect(feedback.lastType, FeedbackType.positive);
      expect(
        _messageById(container, _assistantMessageId).myFeedback!.type,
        FeedbackType.positive,
      );
    });

    test('switching from positive to negative updates the rating', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.positive),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(_assistantMessageId, type: FeedbackType.negative);

      expect(feedback.calls, 1);
      expect(
        _messageById(container, _assistantMessageId).myFeedback!.type,
        FeedbackType.negative,
      );
    });

    test('re-selecting the same rating sends nothing', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.positive),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(_assistantMessageId, type: FeedbackType.positive);

      // There is no delete endpoint, so the rating stays as it was and no
      // pointless request goes out.
      expect(feedback.calls, 0);
      expect(
        _messageById(container, _assistantMessageId).myFeedback!.type,
        FeedbackType.positive,
      );
    });

    test('a rating toggle omits the comment so the backend keeps it', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.positive, comment: 'bagus'),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(_assistantMessageId, type: FeedbackType.negative);

      expect(feedback.lastCommentWasSent, isFalse);
    });

    test('a comment is sent when the dialog supplies one', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.negative),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(
            _assistantMessageId,
            type: FeedbackType.negative,
            comment: 'jawabannya kurang lengkap',
          );

      // Same type, but a comment makes it a real change rather than a no-op.
      expect(feedback.calls, 1);
      expect(feedback.lastComment, 'jawabannya kurang lengkap');
      expect(
        _messageById(container, _assistantMessageId).myFeedback!.comment,
        'jawabannya kurang lengkap',
      );
    });

    test('a USER message is never rated', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(_userMessageId, MessageRole.user),
          _message(_assistantMessageId, MessageRole.assistant),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      await container
          .read(chatControllerProvider(_conversationId).notifier)
          .submitFeedback(_userMessageId, type: FeedbackType.positive);

      // The backend answers 400 for this; the client does not even ask.
      expect(feedback.calls, 0);
      expect(_messageById(container, _userMessageId).myFeedback, isNull);
      expect(
        _messageById(container, _userMessageId).canReceiveFeedback,
        isFalse,
      );
    });
  });

  group('failure handling', () {
    test('rolls back to unrated when the request fails', () async {
      final chat = _FakeChatRepository(
        messages: [_message(_assistantMessageId, MessageRole.assistant)],
      );
      final feedback = _FakeFeedbackRepository()
        ..error = const NetworkException();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      final notifier = container.read(
        chatControllerProvider(_conversationId).notifier,
      );

      await expectLater(
        notifier.submitFeedback(
          _assistantMessageId,
          type: FeedbackType.positive,
        ),
        throwsA(isA<NetworkException>()),
      );

      expect(_messageById(container, _assistantMessageId).myFeedback, isNull);
    });

    test('rolls back to the previous rating, not to unrated', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.positive, comment: 'bagus'),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository()
        ..error = const NetworkException();
      final container = _container(chat: chat, feedback: feedback);

      await _load(container);
      final notifier = container.read(
        chatControllerProvider(_conversationId).notifier,
      );

      await expectLater(
        notifier.submitFeedback(
          _assistantMessageId,
          type: FeedbackType.negative,
        ),
        throwsA(isA<NetworkException>()),
      );

      final restored = _messageById(container, _assistantMessageId).myFeedback!;
      expect(restored.type, FeedbackType.positive);
      expect(restored.comment, 'bagus');
    });
  });

  group('reopening a conversation', () {
    test('shows the rating that was already given', () async {
      final chat = _FakeChatRepository(
        messages: [
          _message(
            _assistantMessageId,
            MessageRole.assistant,
            myFeedback: _feedback(FeedbackType.negative, comment: 'kurang'),
          ),
        ],
      );
      final feedback = _FakeFeedbackRepository();
      final container = _container(chat: chat, feedback: feedback);

      final state = await _load(container);

      // Loaded with the conversation — no extra request per message.
      expect(feedback.calls, 0);
      expect(state.messages.single.myFeedback!.type, FeedbackType.negative);
      expect(state.messages.single.myFeedback!.comment, 'kurang');
    });
  });
}
