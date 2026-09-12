import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_feedback.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/feedback_type.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_role.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Message _message(MessageRole role, {MessageFeedback? myFeedback}) {
  return Message(
    id: 'm1',
    role: role,
    content: role == MessageRole.user ? 'berapa lama refund?' : 'Tujuh hari.',
    createdAt: DateTime(2026, 9, 8),
    myFeedback: myFeedback,
  );
}

Future<void> _pumpBubble(WidgetTester tester, Message message) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: MessageBubble(message: message, conversationId: 'c1'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('an assistant answer offers both ratings', (tester) async {
    await _pumpBubble(tester, _message(MessageRole.assistant));

    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
  });

  testWidgets('a user question offers no rating at all', (tester) async {
    await _pumpBubble(tester, _message(MessageRole.user));

    // The backend rejects feedback on a USER message with a 400, so the
    // affordance must not appear here.
    expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    expect(find.byIcon(Icons.thumb_down_outlined), findsNothing);
    expect(find.byIcon(Icons.thumb_up), findsNothing);
    expect(find.byIcon(Icons.thumb_down), findsNothing);
  });

  testWidgets('the chosen rating renders filled, the other outlined', (
    tester,
  ) async {
    await _pumpBubble(
      tester,
      _message(
        MessageRole.assistant,
        myFeedback: MessageFeedback(
          id: 'fb-1',
          type: FeedbackType.positive,
          createdAt: DateTime(2026, 9, 8),
          updatedAt: DateTime(2026, 9, 8),
        ),
      ),
    );

    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
  });

  testWidgets('the comment action appears only after a rating exists', (
    tester,
  ) async {
    await _pumpBubble(tester, _message(MessageRole.assistant));
    expect(find.text('+ komentar'), findsNothing);

    await _pumpBubble(
      tester,
      _message(
        MessageRole.assistant,
        myFeedback: MessageFeedback(
          id: 'fb-1',
          type: FeedbackType.negative,
          createdAt: DateTime(2026, 9, 8),
          updatedAt: DateTime(2026, 9, 8),
        ),
      ),
    );
    expect(find.text('+ komentar'), findsOneWidget);
  });

  testWidgets('an existing comment is labelled differently', (tester) async {
    await _pumpBubble(
      tester,
      _message(
        MessageRole.assistant,
        myFeedback: MessageFeedback(
          id: 'fb-1',
          type: FeedbackType.negative,
          comment: 'kurang lengkap',
          createdAt: DateTime(2026, 9, 8),
          updatedAt: DateTime(2026, 9, 8),
        ),
      ),
    );

    expect(find.text('Komentar'), findsOneWidget);
    expect(find.text('+ komentar'), findsNothing);
  });
}
