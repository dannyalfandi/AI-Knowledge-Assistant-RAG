import '../repositories/documents_repository.dart';

/// Kicks off extraction → chunking → embedding for a document. Safe to re-run
/// on a `FAILED` document; the backend rejects it while already `PROCESSING`.
class ProcessDocumentUseCase {
  const ProcessDocumentUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<void> call(String id) => _repository.process(id);
}
