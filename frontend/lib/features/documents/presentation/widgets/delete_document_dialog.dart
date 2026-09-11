import 'package:flutter/material.dart';

/// Confirmation before a destructive delete. Returns `true` only when the admin
/// explicitly confirms; deleting a document also drops its chunks and
/// embeddings on the backend, so it is not undoable.
Future<bool> confirmDeleteDocument(
  BuildContext context, {
  required String documentName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus dokumen?'),
      content: Text(
        '"$documentName" beserta seluruh chunk dan embedding-nya akan dihapus '
        'permanen. Tindakan ini tidak bisa dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
