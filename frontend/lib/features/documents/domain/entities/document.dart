import 'document_status.dart';
import 'document_uploader.dart';

/// A document in the knowledge base, independent of any transport concern.
class Document {
  const Document({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    required this.chunkCount,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
    this.uploadedBy,
  });

  final String id;
  final String originalName;
  final String mimeType;

  /// Size in bytes. The backend serialises this `BigInt` column as a string.
  final int fileSize;

  final DocumentStatus status;

  /// Number of indexed chunks; meaningful once [status] is
  /// [DocumentStatus.indexed].
  final int chunkCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Why processing failed. Only set while [status] is [DocumentStatus.failed].
  final String? errorMessage;

  final DocumentUploader? uploadedBy;

  bool get isProcessing => status == DocumentStatus.processing;

  /// Used for the optimistic flip to `PROCESSING` right after the backend
  /// accepts a process request, before the first poll comes back.
  Document copyWithProcessing() {
    return Document(
      id: id,
      originalName: originalName,
      mimeType: mimeType,
      fileSize: fileSize,
      status: DocumentStatus.processing,
      chunkCount: chunkCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      errorMessage: null,
      uploadedBy: uploadedBy,
    );
  }
}
