import 'package:flutter/material.dart';

import '../../../documents/domain/entities/document_status.dart';
import '../../../documents/presentation/widgets/document_status_chip.dart';
import '../../domain/entities/dashboard_summary.dart';
import 'proportion_bar.dart';
import 'stat_tile.dart' show formatCount;

/// Documents per processing status: one labelled row each, ordered along the
/// real pipeline (waiting → running → done → failed) rather than by size, so
/// the shape of the list itself tells the story.
///
/// Rows rather than a stacked bar: four adjacent segments would have to be told
/// apart by colour alone, and this theme's `primary` and `secondary` differ by
/// ΔE 5.7 to normal vision — indistinguishable in practice. Separate rows carry
/// the same part-to-whole information with the identity on a chip that already
/// pairs an icon with a word.
class DocumentStatusBreakdown extends StatelessWidget {
  const DocumentStatusBreakdown({super.key, required this.summary});

  final DashboardSummary summary;

  static const _pipelineOrder = [
    DocumentStatus.pending,
    DocumentStatus.processing,
    DocumentStatus.indexed,
    DocumentStatus.failed,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dokumen per status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${formatCount(summary.totalDocuments)} dokumen total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (!summary.hasDocuments)
              Text(
                'Belum ada dokumen yang diunggah.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final status in _pipelineOrder)
                _StatusRow(
                  status: status,
                  count: summary.countFor(status),
                  total: summary.totalDocuments,
                ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
  });

  final DocumentStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total <= 0 ? 0 : (count / total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The same chip the documents list uses, so a status is named and
              // coloured identically on both screens.
              DocumentStatusChip(status: status),
              const Spacer(),
              Text(
                formatCount(count),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($percent%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ProportionBar(value: count, total: total),
        ],
      ),
    );
  }
}
