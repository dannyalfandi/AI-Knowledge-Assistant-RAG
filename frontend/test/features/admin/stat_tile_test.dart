import 'package:enterprise_knowledge_assistant/features/admin/presentation/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a tile with a caption is the same height as one without, in the same row',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: StatTile(
                    label: 'Pengguna',
                    value: 12,
                    icon: Icons.people_outline,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: StatTile(
                    label: 'Pertanyaan',
                    value: 34,
                    icon: Icons.help_outline,
                    caption: '20 terjawab',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));

      final withoutCaptionHeight = tester.getSize(cards.at(0)).height;
      final withCaptionHeight = tester.getSize(cards.at(1)).height;

      expect(withoutCaptionHeight, withCaptionHeight);
    },
  );

  testWidgets('the caption still renders its text when present', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatTile(
            label: 'Pertanyaan',
            value: 34,
            icon: Icons.help_outline,
            caption: '20 terjawab',
          ),
        ),
      ),
    );

    expect(find.text('20 terjawab'), findsOneWidget);
  });
}
