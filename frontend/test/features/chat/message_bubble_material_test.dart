import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_role.dart';
import 'package:enterprise_knowledge_assistant/features/chat/domain/entities/message_source.dart';
import 'package:enterprise_knowledge_assistant/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for the debug check in `ListTile`, which reports
/// "ListTile background color or ink splashes may be invisible" when the
/// nearest ancestor with a background colour is a plain DecoratedBox instead of
/// a Material. The chat bubble paints its own background, so it has to be a
/// Material for the sources ExpansionTile inside it to render correctly.
///
/// `FlutterError.reportError` inside that assert fails a widget test, so simply
/// rendering and expanding the panel is the test.
Message _answerWithSources() {
  return Message(
    id: 'm1',
    role: MessageRole.assistant,
    content: 'Refund maksimal 7 hari.',
    createdAt: DateTime(2026, 9, 8),
    sources: const [
      MessageSource(
        documentChunkId: 'chunk-1',
        documentId: 'doc-1',
        documentName: 'Refund Policy.pdf',
        chunkIndex: 5,
        content: 'Refund maksimal 7 hari setelah barang diterima.',
        similarityScore: 0.81,
        pageNumber: 4,
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Message message) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [MessageBubble(message: message, conversationId: 'c1')],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the bubble provides a Material ancestor for its ListTiles', (
    tester,
  ) async {
    await _pump(tester, _answerWithSources());

    final sourcesTile = find.text('1 sumber');
    expect(sourcesTile, findsOneWidget);

    // Fails if ListTile's debug check reported the missing Material.
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanding the sources panel reports no Material error', (
    tester,
  ) async {
    await _pump(tester, _answerWithSources());

    await tester.tap(find.text('1 sumber'));
    await tester.pumpAndSettle();

    expect(find.text('Refund Policy.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The nested per-source tile is a ListTile too; open it as well.
    await tester.tap(find.text('Refund Policy.pdf'));
    await tester.pumpAndSettle();

    expect(
      find.text('Refund maksimal 7 hari setelah barang diterima.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
