import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/picked_document.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';

/// Thin pass-through to the remote data source: documents have no local cache
/// or offline story, so there is nothing to reconcile here.
class DocumentsRepositoryImpl implements DocumentsRepository {
  DocumentsRepositoryImpl({required this.remote});

  final DocumentsRemoteDataSource remote;

  @override
  Future<List<Document>> list() => remote.list();

  @override
  Future<Document> getById(String id) => remote.getById(id);

  @override
  Future<Document> upload(
    PickedDocument file, {
    UploadProgressCallback? onProgress,
  }) {
    return remote.upload(file, onProgress: onProgress);
  }

  @override
  Future<void> process(String id) => remote.process(id);

  @override
  Future<void> delete(String id) => remote.delete(id);
}

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepositoryImpl(
    remote: ref.watch(documentsRemoteDataSourceProvider),
  );
});
