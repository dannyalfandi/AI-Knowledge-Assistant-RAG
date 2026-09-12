import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/datasources/feedback_remote_datasource.dart';

/// Collects the optional note attached to a rating.
///
/// Returns the text to save, or null when the user cancels — null means "leave
/// the stored comment as it is", which is also how the backend reads an absent
/// `comment` field.
Future<String?> showFeedbackCommentDialog(
  BuildContext context, {
  String? initialComment,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) =>
        _FeedbackCommentDialog(initialComment: initialComment),
  );
}

class _FeedbackCommentDialog extends StatefulWidget {
  const _FeedbackCommentDialog({this.initialComment});

  final String? initialComment;

  @override
  State<_FeedbackCommentDialog> createState() => _FeedbackCommentDialogState();
}

class _FeedbackCommentDialogState extends State<_FeedbackCommentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialComment ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialComment != null;

    return AlertDialog(
      title: Text(isEditing ? 'Ubah komentar' : 'Tambah komentar'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: FeedbackRemoteDataSource.maxCommentLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              FeedbackRemoteDataSource.maxCommentLength,
            ),
          ],
          decoration: const InputDecoration(
            hintText: 'Apa yang kurang tepat atau sudah membantu?',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
