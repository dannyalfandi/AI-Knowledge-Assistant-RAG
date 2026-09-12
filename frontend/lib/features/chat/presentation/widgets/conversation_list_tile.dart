import 'package:flutter/material.dart';

import '../../domain/entities/conversation.dart';

/// One row in the conversation list.
class ConversationListTile extends StatelessWidget {
  const ConversationListTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.forum_outlined,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          conversation.title ?? 'Percakapan tanpa judul',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          '${conversation.messageCount} pesan · '
          '${formatConversationDate(conversation.updatedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: 'Hapus percakapan',
        ),
      ),
    );
  }
}

String formatConversationDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}
