import '../../domain/entities/document.dart';
import '../../domain/entities/document_status.dart';
import '../../domain/entities/document_uploader.dart';

/// Transport representation of [Document].
///
/// Two backend shapes feed this model:
///  - `GET /api/documents` and `GET /api/documents/:id` return the full row,
///    including `uploadedBy` and `_count.chunks`.
///  - `POST /api/documents` returns only the subset the upload flow needs; the
///    missing fields fall back to their empty values.
///
/// Note `fileSize` arrives as a *string* — it is a `BigInt` column and the
/// backend serialises it with `.toString()` so it survives JSON.
class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.originalName,
    required super.mimeType,
    required super.fileSize,
    required super.status,
    required super.chunkCount,
    required super.createdAt,
    required super.updatedAt,
    super.errorMessage,
    super.uploadedBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['createdAt']);

    return DocumentModel(
      id: json['id'] as String,
      originalName: json['originalName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      fileSize: _parseSize(json['fileSize']),
      status: _parseStatus(json['status']),
      chunkCount: _parseChunkCount(json['_count']),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : _parseDate(json['updatedAt']),
      errorMessage: (json['errorMessage'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['errorMessage'] as String,
      uploadedBy: _parseUploader(json['uploadedBy']),
    );
  }

  static DocumentStatus _parseStatus(Object? raw) {
    return switch (raw) {
      'PENDING' => DocumentStatus.pending,
      'PROCESSING' => DocumentStatus.processing,
      'INDEXED' => DocumentStatus.indexed,
      'FAILED' => DocumentStatus.failed,
      _ => DocumentStatus.unknown,
    };
  }

  static int _parseSize(Object? raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    if (raw is num) return raw.toInt();
    return 0;
  }

  static int _parseChunkCount(Object? raw) {
    if (raw is Map && raw['chunks'] is int) return raw['chunks'] as int;
    return 0;
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DocumentUploader? _parseUploader(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    if (id is! String) return null;

    return DocumentUploader(
      id: id,
      name: raw['name'] as String? ?? '',
      email: raw['email'] as String? ?? '',
    );
  }
}
