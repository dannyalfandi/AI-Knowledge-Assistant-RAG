import 'package:flutter/material.dart';

/// One headline number with its label.
///
/// A handful of totals is a row of stat tiles, not a bar chart with one bar
/// each — there is nothing to compare along an axis, so the number itself is
/// the visualisation.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
  });

  final String label;
  final int value;
  final IconData icon;

  /// Optional second line, for context the number alone does not carry.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatCount(value),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            // Reserve the caption's line height even when there is no caption,
            // so tiles in the same grid row line up regardless of which ones
            // have a second line. `maintainSize` measures the real text style
            // (font, scale factor) instead of a guessed fixed height, so it
            // stays correct under larger accessibility text sizes too.
            Visibility(
              visible: caption != null,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(
                caption ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thousands-separated, so five and six digit totals stay readable at a glance.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return buffer.toString();
}
