import 'package:flutter/material.dart';

import '../../domain/entities/document_status.dart';

/// Visual indicator for a document's processing status. Colour *and* icon carry
/// the meaning, so the status is still readable without relying on colour
/// alone; `PROCESSING` additionally spins to signal that it is live.
class DocumentStatusChip extends StatelessWidget {
  const DocumentStatusChip({super.key, required this.status});

  final DocumentStatus status;

  static String label(DocumentStatus status) => switch (status) {
    DocumentStatus.pending => 'Menunggu',
    DocumentStatus.processing => 'Diproses',
    DocumentStatus.indexed => 'Terindeks',
    DocumentStatus.failed => 'Gagal',
    DocumentStatus.unknown => 'Tidak diketahui',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (Color background, Color foreground) = switch (status) {
      DocumentStatus.pending => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      DocumentStatus.processing => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      DocumentStatus.indexed => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      DocumentStatus.failed => (colors.errorContainer, colors.onErrorContainer),
      DocumentStatus.unknown => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusLeading(status: status, color: foreground),
          const SizedBox(width: 6),
          Text(
            label(status),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLeading extends StatelessWidget {
  const _StatusLeading({required this.status, required this.color});

  final DocumentStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (status == DocumentStatus.processing) {
      return SizedBox.square(
        dimension: 12,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    final icon = switch (status) {
      DocumentStatus.pending => Icons.schedule,
      DocumentStatus.indexed => Icons.check_circle_outline,
      DocumentStatus.failed => Icons.error_outline,
      _ => Icons.help_outline,
    };

    return Icon(icon, size: 14, color: color);
  }
}
