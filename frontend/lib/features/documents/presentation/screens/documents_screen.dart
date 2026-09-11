import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/document.dart';
import '../providers/documents_controller.dart';
import '../widgets/delete_document_dialog.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/document_upload_sheet.dart';
import 'document_detail_screen.dart';

/// ADMIN-only document management: list, upload, process, delete.
///
/// Rows with status `PROCESSING` refresh themselves — see [DocumentsController]
/// — so the admin does not have to refresh manually while indexing runs.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  static const path = '/documents';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsState = ref.watch(documentsControllerProvider);
    final controller = ref.read(documentsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumen'),
        leading: const AppBackButton(fallbackLocation: HomeScreen.path),
        actions: [
          if (documentsState.value?.isRefreshing ?? false)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Unggah'),
      ),
      body: documentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat daftar dokumen.',
          onRetry: controller.refresh,
        ),
        data: (state) {
          if (state.documents.isEmpty) return const _EmptyView();

          return Column(
            children: [
              if (state.pollingStoppedMessage != null)
                _PollingStoppedBanner(
                  message: state.pollingStoppedMessage!,
                  onRefresh: controller.refresh,
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: state.documents.length,
                    itemBuilder: (context, index) {
                      final document = state.documents[index];

                      return DocumentListTile(
                        document: document,
                        onTap: () => context.go(
                          DocumentDetailScreen.pathFor(document.id),
                        ),
                        onProcess: () => _process(context, ref, document),
                        onDelete: () => _delete(context, ref, document),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final uploaded = await DocumentUploadSheet.show(context);
    if (!uploaded) return;

    await ref.read(documentsControllerProvider.notifier).reloadAfterUpload();

    if (context.mounted) {
      notifyDocumentAction(
        context,
        'Dokumen berhasil diunggah. Jalankan "Proses" untuk mengindeksnya.',
      );
    }
  }

  Future<void> _process(
    BuildContext context,
    WidgetRef ref,
    Document document,
  ) async {
    try {
      await ref.read(documentsControllerProvider.notifier).process(document.id);
      if (context.mounted) {
        notifyDocumentAction(
          context,
          'Pemrosesan "${document.originalName}" dimulai.',
        );
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
      }
    } on AppException catch (error) {
      if (context.mounted) {
        notifyDocumentAction(context, error.message, isError: true);
      }
    }
  }
}

/// Shared snack bar for the outcome of a document action.
void notifyDocumentAction(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colors = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colors.error : null,
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Belum ada dokumen', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Unggah PDF kebijakan, SOP, atau FAQ perusahaan untuk mulai '
              'membangun knowledge base.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when automatic refreshing gave up (a document sat at `PROCESSING` for
/// too long, or the backend kept failing), so a stale list is never presented
/// as live data.
class _PollingStoppedBanner extends StatelessWidget {
  const _PollingStoppedBanner({required this.message, required this.onRefresh});

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colors.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: colors.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Muat ulang')),
        ],
      ),
    );
  }
}
