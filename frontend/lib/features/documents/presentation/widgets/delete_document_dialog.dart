import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_dialog.dart';

/// Confirmation before a destructive delete. Returns `true` only when the admin
/// explicitly confirms; deleting a document also drops its chunks and
/// embeddings on the backend, so it is not undoable.
Future<bool> confirmDeleteDocument(
  BuildContext context, {
  required String documentName,
}) {
  return confirmDestructiveAction(
    context,
    title: 'Hapus dokumen?',
    message:
        '"$documentName" beserta seluruh chunk dan embedding-nya akan dihapus '
        'permanen. Tindakan ini tidak bisa dibatalkan.',
  );
}
