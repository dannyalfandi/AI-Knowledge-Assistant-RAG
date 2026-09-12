import 'package:flutter/material.dart';

/// Assistant-side bubble replacing an answer that never arrived.
///
/// The question itself stays on screen above this; retrying re-sends it, which
/// is safe because the backend stores a question only together with its answer.
class FailedAskBubble extends StatelessWidget {
  const FailedAskBubble({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text('Buang'),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
