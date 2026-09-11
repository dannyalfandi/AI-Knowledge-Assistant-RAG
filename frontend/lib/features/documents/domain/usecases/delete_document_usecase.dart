import '../repositories/documents_repository.dart';

/// Removes a document, its stored file, and (via cascade) its chunks and
/// embeddings.
class DeleteDocumentUseCase {
  const DeleteDocumentUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
