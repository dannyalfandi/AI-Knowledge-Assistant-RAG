import '../entities/document.dart';
import '../entities/picked_document.dart';
import '../repositories/documents_repository.dart';

/// Uploads a new PDF. The resulting document starts at `PENDING`; indexing is a
/// separate, explicit step (see [ProcessDocumentUseCase]).
class UploadDocumentUseCase {
  const UploadDocumentUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Document> call(
    PickedDocument file, {
    UploadProgressCallback? onProgress,
  }) {
    return _repository.upload(file, onProgress: onProgress);
  }
}
