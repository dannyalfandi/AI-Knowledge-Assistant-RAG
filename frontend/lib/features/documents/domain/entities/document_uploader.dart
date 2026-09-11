/// The admin who uploaded a document, as embedded in the document payload.
class DocumentUploader {
  const DocumentUploader({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  String get displayName => name.isEmpty ? email : name;
}
