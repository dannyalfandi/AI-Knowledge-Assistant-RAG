import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/back_navigation.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_status.dart';
import '../providers/document_detail_controller.dart';
import '../providers/documents_controller.dart';
import '../widgets/delete_document_dialog.dart';
import '../widgets/document_list_tile.dart' show formatFileSize;
import '../widgets/document_status_chip.dart';
import 'documents_screen.dart';

/// Full metadata for one document, including the failure reason and the chunk
/// count produced by indexing. Polls itself while the document is `PROCESSING`.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  /// Sub-route segment nested under [DocumentsScreen.path], which makes the
  /// full route `/documents/:id`.
  static const routeSegment = ':id';

  static String pathFor(String id) => '/documents/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = documentDetailControllerProvider(documentId);
    final detailState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dokumen'),
        // Opened from the list this pops; opened directly by URL (a reload or
        // a shared link, both easy on the web) it falls back to the list.
        leading: const AppBackButton(fallbackLocation: DocumentsScreen.path),
        actions: [
          if (detailState.value?.isRefreshing ?? false)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
            ),
        ],
      ),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is AppException
                      ? error.message
                      : 'Gagal memuat dokumen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: controller.refresh,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (state) => _DetailBody(
          document: state.document,
          pollingStoppedMessage: state.pollingStoppedMessage,
          onRefresh: controller.refresh,
          onProcess: () => _process(context, controller),
          onDelete: () => _delete(context, ref, state.document),
        ),
      ),
    );
  }

  Future<void> _process(
    BuildContext context,
    DocumentDetailController controller,
  ) async {
    try {
      await controller.process();
      if (context.mounted) {
        notifyDocumentAction(context, 'Pemrosesan dimulai.');
      }
    } on AppException catch (error) {
      if (context.mounted) {
        notifyDocumentAction(context, error.message, isError: true);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    final confirmed = await confirmDeleteDocument(
      context,
      documentName: document.originalName,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(documentsControllerProvider.notifier).delete(document.id);
      if (context.mounted) {
        notifyDocumentAction(context, '"${document.originalName}" dihapus.');
        context.go(DocumentsScreen.path);
      }
    } on AppException catch (error) {
      if (context.mounted) {
        notifyDocumentAction(context, error.message, isError: true);
      }
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.document,
    required this.pollingStoppedMessage,
    required this.onRefresh,
    required this.onProcess,
    required this.onDelete,
  });

  final Document document;
  final String? pollingStoppedMessage;
  final VoidCallback onRefresh;
  final VoidCallback onProcess;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (pollingStoppedMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pollingStoppedMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRefresh,
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(document.originalName, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        DocumentStatusChip(status: document.status),
        const SizedBox(height: 24),
        _Field(label: 'Ukuran', value: formatFileSize(document.fileSize)),
        _Field(label: 'Tipe', value: document.mimeType),
        _Field(
          label: 'Jumlah chunk',
          value: document.status == DocumentStatus.indexed
              ? '${document.chunkCount}'
              : '— (belum terindeks)',
        ),
        _Field(
          label: 'Diunggah oleh',
          value: document.uploadedBy?.displayName ?? '—',
        ),
        _Field(label: 'Diunggah pada', value: _formatDate(document.createdAt)),
        _Field(label: 'Diperbarui', value: _formatDate(document.updatedAt)),
        if (document.status == DocumentStatus.failed &&
            document.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penyebab kegagalan',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  document.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (!document.isProcessing)
          FilledButton.icon(
            onPressed: onProcess,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              document.status == DocumentStatus.indexed
                  ? 'Proses ulang'
                  : 'Proses sekarang',
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus dokumen'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}
