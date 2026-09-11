import '../entities/document.dart';
import '../repositories/documents_repository.dart';

/// Loads every document in the knowledge base, newest first.
class ListDocumentsUseCase {
  const ListDocumentsUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<List<Document>> call() => _repository.list();
}
