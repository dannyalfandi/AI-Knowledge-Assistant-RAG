import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/picked_document.dart';
import '../providers/document_upload_controller.dart';
import 'document_list_tile.dart' show formatFileSize;

/// Bottom sheet that picks a PDF and uploads it, showing send progress.
///
/// `file_picker` is only referenced here: the rest of the feature works with
/// [PickedDocument], so swapping the picker would not touch the data or domain
/// layers.
class DocumentUploadSheet extends ConsumerStatefulWidget {
  const DocumentUploadSheet({super.key});

  /// Returns `true` when a document was uploaded, so the caller can refresh.
  static Future<bool> show(BuildContext context) async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DocumentUploadSheet(),
    );
    return uploaded ?? false;
  }

  @override
  ConsumerState<DocumentUploadSheet> createState() =>
      _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends ConsumerState<DocumentUploadSheet> {
  /// Mirrors the backend's Multer limit so an oversized file is rejected before
  /// spending bandwidth on it.
  static const _maxFileSizeBytes = 10 * 1024 * 1024;

  PickedDocument? _file;
  String? _pickErrorMessage;

  Future<void> _pickFile() async {
    setState(() => _pickErrorMessage = null);

    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Pilih dokumen PDF',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (picked == null) return;

      // Reading the bytes up front keeps web (no file path) and desktop on the
      // same code path.
      final bytes = await picked.readAsBytes();

      if (bytes.length > _maxFileSizeBytes) {
        if (mounted) {
          setState(() {
            _file = null;
            _pickErrorMessage =
                'Ukuran file ${formatFileSize(bytes.length)} melebihi batas '
                '10 MB.';
          });
        }
        return;
      }

      if (!mounted) return;
      setState(() => _file = PickedDocument(name: picked.name, bytes: bytes));
      ref.read(documentUploadControllerProvider.notifier).reset();
    } catch (_) {
      if (mounted) {
        setState(() => _pickErrorMessage = 'Gagal membaca file yang dipilih.');
      }
    }
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;

    final uploaded = await ref
        .read(documentUploadControllerProvider.notifier)
        .upload(file);

    if (uploaded && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upload = ref.watch(documentUploadControllerProvider);
    final file = _file;
    final errorMessage = _pickErrorMessage ?? upload.errorMessage;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unggah dokumen', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Hanya file PDF, maksimal 10 MB. Setelah diunggah, dokumen '
              'berstatus "Menunggu" sampai Anda menjalankan proses indexing.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: upload.inProgress ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(file == null ? 'Pilih file PDF' : 'Ganti file'),
            ),
            if (file != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatFileSize(file.size),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                        errorMessage,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (upload.inProgress) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: upload.progress),
              const SizedBox(height: 8),
              Text(
                'Mengunggah ${(upload.progress * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: upload.inProgress
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: file == null || upload.inProgress ? null : _upload,
                  child: const Text('Unggah'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
