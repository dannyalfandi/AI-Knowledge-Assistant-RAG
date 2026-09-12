import 'package:flutter/material.dart';

import '../../domain/entities/message_source.dart';

/// Citations under an assistant answer.
///
/// Collapsed it shows only what identifies each source (document name and
/// page); the chunk text is long enough that rendering all five at once would
/// bury the answer, so it is revealed per source on demand.
class MessageSourcesPanel extends StatelessWidget {
  const MessageSourcesPanel({super.key, required this.sources});

  final List<MessageSource> sources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      // Keep the divider lines out of an already dense bubble.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Icon(
          Icons.menu_book_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '${sources.length} sumber',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [for (final source in sources) _SourceEntry(source: source)],
      ),
    );
  }
}

class _SourceEntry extends StatelessWidget {
  const _SourceEntry({required this.source});

  final MessageSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            source.documentName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (source.pageNumber != null) 'Halaman ${source.pageNumber}',
              'Skor ${source.similarityScore.toStringAsFixed(3)}',
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SelectableText(
                source.content,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
