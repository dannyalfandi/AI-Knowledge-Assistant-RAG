import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/picked_document.dart';
import 'documents_providers.dart';

/// Progress of the one upload that can be in flight at a time.
class UploadState {
  const UploadState._({
    required this.inProgress,
    required this.progress,
    this.errorMessage,
  });

  const UploadState.idle() : this._(inProgress: false, progress: 0);

  const UploadState.uploading(double progress)
    : this._(inProgress: true, progress: progress);

  const UploadState.failed(String message)
    : this._(inProgress: false, progress: 0, errorMessage: message);

  final bool inProgress;

  /// 0.0–1.0 of bytes sent.
  final double progress;

  final String? errorMessage;
}

class DocumentUploadController extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadState.idle();

  /// Uploads [file] and returns `true` on success. Failures are kept in the
  /// state (so the upload sheet can render them inline) rather than thrown.
  Future<bool> upload(PickedDocument file) async {
    if (state.inProgress) return false;

    state = const UploadState.uploading(0);

    try {
      await ref
          .read(uploadDocumentUseCaseProvider)
          .call(
            file,
            onProgress: (sent, total) {
              if (!state.inProgress) return;
              state = UploadState.uploading(
                total <= 0 ? 0 : (sent / total).clamp(0.0, 1.0),
              );
            },
          );

      state = const UploadState.idle();
      return true;
    } on AppException catch (error) {
      state = UploadState.failed(error.message);
      return false;
    } catch (_) {
      state = const UploadState.failed('Unggah dokumen gagal.');
      return false;
    }
  }

  void reset() => state = const UploadState.idle();
}

final documentUploadControllerProvider =
    NotifierProvider.autoDispose<DocumentUploadController, UploadState>(
      DocumentUploadController.new,
    );
