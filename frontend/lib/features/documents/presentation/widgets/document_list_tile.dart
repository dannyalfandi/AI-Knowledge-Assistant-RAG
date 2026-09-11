import 'package:flutter/material.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/document_status.dart';
import 'document_status_chip.dart';

/// One row in the documents list: name, status, and the status-specific detail
/// an admin actually needs — chunk count once indexed, the failure reason when
/// it failed.
class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onProcess,
    required this.onDelete,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback onProcess;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.originalName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DocumentStatusChip(status: document.status),
                        Text(
                          formatFileSize(document.fileSize),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (document.status == DocumentStatus.indexed)
                          Text(
                            '${document.chunkCount} chunk',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (document.status == DocumentStatus.failed &&
                        document.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        document.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _RowActions(
                document: document,
                onProcess: onProcess,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.document,
    required this.onProcess,
    required this.onDelete,
  });

  final Document document;
  final VoidCallback onProcess;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RowAction>(
      tooltip: 'Aksi dokumen',
      onSelected: (action) => switch (action) {
        _RowAction.process => onProcess(),
        _RowAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        // The backend answers 409 while a document is already PROCESSING, so
        // the option is hidden rather than offered and rejected. INDEXED shows
        // it as a deliberate re-index.
        if (!document.isProcessing)
          PopupMenuItem(
            value: _RowAction.process,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow),
              title: Text(
                document.status == DocumentStatus.indexed
                    ? 'Proses ulang'
                    : 'Proses',
              ),
            ),
          ),
        PopupMenuItem(
          value: _RowAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Hapus'),
          ),
        ),
      ],
    );
  }
}

enum _RowAction { process, delete }

/// Formats a byte count for display (the backend sends it as a string because
/// the column is a `BigInt`).
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
