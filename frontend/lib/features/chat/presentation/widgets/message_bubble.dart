import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../domain/entities/message_role.dart';
import 'message_feedback_bar.dart';
import 'message_sources_panel.dart';

/// One chat bubble: the user's on the right, the assistant's on the left.
///
/// An answer of "Informasi tidak ditemukan di knowledge base." is rendered like
/// any other answer — the backend already decides when to say it, and styling
/// it differently would just add a second, redundant signal.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.conversationId,
  });

  final Message message;

  /// Needed by the feedback bar to address the right chat controller.
  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role.isUser;

    final background = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          // A Material rather than a coloured Container: the bubble holds an
          // ExpansionTile (sources) and buttons (feedback), which paint their
          // background and ink on the nearest Material ancestor. Without one
          // here they would paint on the Scaffold, behind this opaque bubble —
          // which is exactly what ListTile's debug check warns about.
          child: Material(
            color: background,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 16 : 4),
              topRight: Radius.circular(isUser ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: SelectableText(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (message.hasSources) ...[
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  MessageSourcesPanel(sources: message.sources),
                ],
                if (message.canReceiveFeedback)
                  MessageFeedbackBar(
                    conversationId: conversationId,
                    message: message,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's question while it is being answered or after the answer failed.
/// Visually a user bubble, dimmed to signal "not stored yet".
class PendingQuestionBubble extends StatelessWidget {
  const PendingQuestionBubble({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Role is only used to decide sides; exposed for tests and callers that build
/// a bubble from a role directly.
bool isUserRole(MessageRole role) => role.isUser;
