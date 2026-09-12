import 'package:enterprise_knowledge_assistant/features/chat/data/models/ask_result_model.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/models/conversation_model.dart';
import 'package:enterprise_knowledge_assistant/features/chat/data/models/message_model.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_role.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _sourceJson({String name = 'Refund Policy.pdf'}) {
  return {
    'documentChunkId': 'chunk-1',
    'documentId': 'doc-1',
    'documentName': name,
    'pageNumber': 4,
    'chunkIndex': 5,
    'content': 'Refund maksimal 7 hari setelah barang diterima.',
    'similarityScore': 0.81,
  };
}

void main() {
  group('MessageModel', () {
    test('parses an assistant message with its citations', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'Refund maksimal 7 hari.',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'sources': [_sourceJson()],
      });

      expect(message.role, MessageRole.assistant);
      expect(message.hasSources, isTrue);
      expect(message.sources.single.documentName, 'Refund Policy.pdf');
      expect(message.sources.single.pageNumber, 4);
      expect(message.sources.single.similarityScore, closeTo(0.81, 1e-9));
    });

    test('a USER message has no sources', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'USER',
        'content': 'berapa lama refund?',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'sources': <Object>[],
      });

      expect(message.role, MessageRole.user);
      expect(message.hasSources, isFalse);
    });

    test('a missing sources field is treated as no citations', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'Informasi tidak ditemukan di knowledge base.',
        'createdAt': '2026-09-08T00:00:00.000Z',
      });

      expect(message.sources, isEmpty);
    });

    test('an unknown role degrades instead of throwing', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'SYSTEM',
        'content': 'x',
        'createdAt': '2026-09-08T00:00:00.000Z',
      });

      expect(message.role, MessageRole.unknown);
      expect(message.role.isUser, isFalse);
    });

    test('a null pageNumber survives (chunk with no page attribution)', () {
      final message = MessageModel.fromJson({
        'id': 'm1',
        'role': 'ASSISTANT',
        'content': 'x',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'sources': [
          {..._sourceJson(), 'pageNumber': null},
        ],
      });

      expect(message.sources.single.pageNumber, isNull);
    });
  });

  group('ConversationModel', () {
    test('reads the message count from _count.messages', () {
      final conversation = ConversationModel.fromJson({
        'id': 'c1',
        'title': 'Refund Q&A',
        'createdAt': '2026-09-08T00:00:00.000Z',
        'updatedAt': '2026-09-08T01:00:00.000Z',
        '_count': {'messages': 4},
      });

      expect(conversation.title, 'Refund Q&A');
      expect(conversation.messageCount, 4);
    });

    test('a null or blank title becomes null, not an empty string', () {
      final untitled = ConversationModel.fromJson({
        'id': 'c1',
        'title': null,
        'createdAt': '2026-09-08T00:00:00.000Z',
        '_count': {'messages': 0},
      });
      final blank = ConversationModel.fromJson({
        'id': 'c2',
        'title': '   ',
        'createdAt': '2026-09-08T00:00:00.000Z',
        '_count': {'messages': 0},
      });

      expect(untitled.title, isNull);
      expect(blank.title, isNull);
      // No updatedAt in the payload: it falls back to createdAt.
      expect(untitled.updatedAt, untitled.createdAt);
    });
  });

  group('ConversationDetailModel', () {
    test('parses the message history in order', () {
      final detail = ConversationDetailModel.fromJson({
        'id': 'c1',
        'title': null,
        'createdAt': '2026-09-08T00:00:00.000Z',
        'updatedAt': '2026-09-08T00:00:02.000Z',
        'messages': [
          {
            'id': 'm1',
            'role': 'USER',
            'content': 'q',
            'createdAt': '2026-09-08T00:00:00.000Z',
            'sources': <Object>[],
          },
          {
            'id': 'm2',
            'role': 'ASSISTANT',
            'content': 'a',
            'createdAt': '2026-09-08T00:00:01.000Z',
            'sources': [_sourceJson()],
          },
        ],
      });

      expect(detail.messages.map((m) => m.id), ['m1', 'm2']);
      expect(detail.messages.last.sources, hasLength(1));
    });
  });

  group('AskResultModel', () {
    test('attaches the top-level sources to the assistant message', () {
      // The backend returns `sources` next to `assistantMessage`, not inside
      // it; the model moves them so a fresh answer renders like a stored one.
      final result = AskResultModel.fromJson({
        'conversationId': 'c1',
        'question': 'berapa lama refund?',
        'answer': 'Refund maksimal 7 hari.',
        'userMessage': {
          'id': 'm1',
          'role': 'USER',
          'content': 'berapa lama refund?',
          'createdAt': '2026-09-08T00:00:00.000Z',
        },
        'assistantMessage': {
          'id': 'm2',
          'role': 'ASSISTANT',
          'content': 'Refund maksimal 7 hari.',
          'createdAt': '2026-09-08T00:00:01.000Z',
        },
        'sources': [_sourceJson()],
      });

      expect(result.userMessage.role, MessageRole.user);
      expect(result.userMessage.hasSources, isFalse);
      expect(result.assistantMessage.sources, hasLength(1));
      expect(
        result.assistantMessage.sources.single.documentName,
        'Refund Policy.pdf',
      );
    });

    test('an answer with no retrieval hits carries an empty source list', () {
      final result = AskResultModel.fromJson({
        'userMessage': {
          'id': 'm1',
          'role': 'USER',
          'content': 'q',
          'createdAt': '2026-09-08T00:00:00.000Z',
        },
        'assistantMessage': {
          'id': 'm2',
          'role': 'ASSISTANT',
          'content': 'Informasi tidak ditemukan di knowledge base.',
          'createdAt': '2026-09-08T00:00:01.000Z',
        },
        'sources': <Object>[],
      });

      expect(result.assistantMessage.sources, isEmpty);
      expect(
        result.assistantMessage.content,
        'Informasi tidak ditemukan di knowledge base.',
      );
    });
  });
}
