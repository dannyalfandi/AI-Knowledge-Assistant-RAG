import '../entities/document.dart';
import '../entities/picked_document.dart';

/// Reports upload progress: [sent] and [total] are byte counts. [total] is `-1`
/// when the transport cannot determine the payload size.
typedef UploadProgressCallback = void Function(int sent, int total);

/// Contract the presentation layer depends on. The implementation owns the
/// transport; nothing here knows about `dio`.
///
/// Every method throws an [AppException] on failure — `ForbiddenException` when
/// the signed-in user is not an ADMIN, `NetworkException` when the backend is
/// unreachable, and so on.
abstract interface class DocumentsRepository {
  /// All documents, newest first. The backend returns the full list without
  /// pagination.
  Future<List<Document>> list();

  Future<Document> getById(String id);

  /// Uploads [file] and returns the freshly created document row, which always
  /// starts at `PENDING`.
  Future<Document> upload(
    PickedDocument file, {
    UploadProgressCallback? onProgress,
  });

  /// Asks the backend to (re)extract, chunk, and embed the document. Returns as
  /// soon as the work is scheduled — the document is then `PROCESSING` and the
  /// caller must poll for the outcome.
  Future<void> process(String id);

  Future<void> delete(String id);
}
