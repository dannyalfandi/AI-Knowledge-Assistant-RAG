import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_controller.dart';
import 'feedback_comment_dialog.dart';

/// Thumbs-up / thumbs-down under an assistant answer, plus the optional
/// comment.
///
/// Only rendered for assistant messages — the backend rejects feedback on a
/// USER message with a 400, so the affordance never appears where it cannot
/// work.
class MessageFeedbackBar extends ConsumerStatefulWidget {
  const MessageFeedbackBar({
    super.key,
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final Message message;

  @override
  ConsumerState<MessageFeedbackBar> createState() => _MessageFeedbackBarState();
}

class _MessageFeedbackBarState extends ConsumerState<MessageFeedbackBar> {
  bool _submitting = false;

  Future<void> _submit(FeedbackType type, {String? comment}) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .submitFeedback(widget.message.id, type: type, comment: comment);
    } on AppException catch (error) {
      // The controller has already rolled the icon back to its previous state;
      // a snack bar is enough to say why, without blocking the chat.
      if (mounted) _notify(error.message);
    } catch (_) {
      if (mounted) _notify('Gagal mengirim feedback. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editComment() async {
    final current = widget.message.myFeedback;
    if (current == null) return;

    final comment = await showFeedbackCommentDialog(
      context,
      initialComment: current.comment,
    );
    // Cancelled: leave the stored comment untouched.
    if (comment == null) return;

    await _submit(current.type, comment: comment);
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedback = widget.message.myFeedback;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FeedbackIconButton(
            type: FeedbackType.positive,
            isSelected: feedback?.type == FeedbackType.positive,
            enabled: !_submitting,
            onPressed: () => _submit(FeedbackType.positive),
          ),
          _FeedbackIconButton(
            type: FeedbackType.negative,
            isSelected: feedback?.type == FeedbackType.negative,
            enabled: !_submitting,
            onPressed: () => _submit(FeedbackType.negative),
          ),
          // The comment only makes sense once a rating exists — it annotates
          // the rating rather than standing on its own.
          if (feedback != null)
            TextButton.icon(
              onPressed: _submitting ? null : _editComment,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(
                feedback.hasComment
                    ? Icons.mode_comment
                    : Icons.add_comment_outlined,
                size: 16,
              ),
              label: Text(
                feedback.hasComment ? 'Komentar' : '+ komentar',
                style: theme.textTheme.labelMedium,
              ),
            ),
          if (_submitting)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedbackIconButton extends StatelessWidget {
  const _FeedbackIconButton({
    required this.type,
    required this.isSelected,
    required this.enabled,
    required this.onPressed,
  });

  final FeedbackType type;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = type == FeedbackType.positive;

    // Filled versus outlined carries the state on its own, so it still reads
    // without relying on colour.
    final icon = isSelected
        ? (isPositive ? Icons.thumb_up : Icons.thumb_down)
        : (isPositive ? Icons.thumb_up_outlined : Icons.thumb_down_outlined);

    final color = isSelected
        ? (isPositive ? theme.colorScheme.primary : theme.colorScheme.error)
        : theme.colorScheme.onSurfaceVariant;

    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: color,
      visualDensity: VisualDensity.compact,
      // There is no delete endpoint, so a rating can be changed but never
      // withdrawn; say so instead of leaving a tap that appears to do nothing.
      tooltip: isSelected
          ? 'Feedback terkirim — pilih yang lain untuk mengubah'
          : (isPositive ? 'Jawaban ini membantu' : 'Jawaban ini kurang tepat'),
    );
  }
}
