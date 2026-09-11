import '../entities/document.dart';
import '../repositories/documents_repository.dart';

/// Loads a single document with its processing details.
class GetDocumentUseCase {
  const GetDocumentUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Document> call(String id) => _repository.getById(id);
}
