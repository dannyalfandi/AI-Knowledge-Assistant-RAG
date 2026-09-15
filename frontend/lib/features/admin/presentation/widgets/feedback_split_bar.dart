import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_summary.dart';
import 'stat_tile.dart' show formatCount;

/// Positive against negative feedback.
///
/// This is polarity, not identity, so it gets two opposed poles rather than a
/// categorical palette: the theme's cool `primary` against its warm `error` —
/// the same two colours the thumbs already wear in the chat. The pair separates
/// well under colour-vision deficiency (ΔE 18.2 protan), and each pole still
/// carries an icon, a word and a number, so nothing here rests on colour alone.
///
/// A two-slice pie was the obvious alternative and is the wrong one: angles are
/// harder to compare than lengths, and the split is the whole point.
class FeedbackSplitBar extends StatelessWidget {
  const FeedbackSplitBar({super.key, required this.summary});

  final DashboardSummary summary;

  /// The gap that separates the two fills. White doing the separating, rather
  /// than a border, which would add ink that is not data.
  static const _gap = 2.0;
  static const _barHeight = 14.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final positive = summary.feedbackPositive;
    final negative = summary.feedbackNegative;
    final rated = positive + negative;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feedback jawaban AI', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              rated == 0
                  ? 'Belum ada feedback'
                  : '${formatCount(summary.feedbackTotal)} penilaian total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (rated == 0)
              Text(
                'Belum ada jawaban yang dinilai pengguna.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _SplitBar(positive: positive, negative: negative),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Pole(
                      icon: Icons.thumb_up,
                      label: 'Membantu',
                      count: positive,
                      rated: rated,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _Pole(
                      icon: Icons.thumb_down,
                      label: 'Kurang tepat',
                      count: negative,
                      rated: rated,
                      color: theme.colorScheme.error,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.positive, required this.negative});

  final int positive;
  final int negative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rated = positive + negative;

    // A pole with no ratings takes no width and no gap, so the bar never shows
    // a sliver of a colour that has no data behind it.
    final flexPositive = positive;
    final flexNegative = negative;

    return ClipRRect(
      borderRadius: BorderRadius.circular(FeedbackSplitBar._barHeight / 2),
      child: SizedBox(
        height: FeedbackSplitBar._barHeight,
        child: Row(
          children: [
            if (flexPositive > 0)
              Expanded(
                flex: flexPositive,
                child: ColoredBox(color: theme.colorScheme.primary),
              ),
            if (flexPositive > 0 && flexNegative > 0)
              SizedBox(
                width: FeedbackSplitBar._gap,
                child: ColoredBox(color: theme.colorScheme.surface),
              ),
            if (flexNegative > 0)
              Expanded(
                flex: flexNegative,
                child: ColoredBox(color: theme.colorScheme.error),
              ),
            if (rated == 0) const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _Pole extends StatelessWidget {
  const _Pole({
    required this.icon,
    required this.label,
    required this.count,
    required this.rated,
    required this.color,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final int rated;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = rated == 0 ? 0 : (count / rated * 100).round();

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  // Text wears text tokens; the coloured icon beside it carries
                  // the identity.
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${formatCount(count)} · $percent%',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
