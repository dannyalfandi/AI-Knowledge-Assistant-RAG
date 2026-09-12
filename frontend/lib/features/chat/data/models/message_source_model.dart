import '../../domain/entities/message_source.dart';

/// Transport representation of [MessageSource].
///
/// The same JSON shape arrives from `/ask` (built from the retrieval result)
/// and from `GET /:id` (flattened from the stored `MessageSource` rows).
class MessageSourceModel extends MessageSource {
  const MessageSourceModel({
    required super.documentChunkId,
    required super.documentId,
    required super.documentName,
    required super.chunkIndex,
    required super.content,
    required super.similarityScore,
    super.pageNumber,
  });

  factory MessageSourceModel.fromJson(Map<String, dynamic> json) {
    return MessageSourceModel(
      documentChunkId: json['documentChunkId'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      documentName: json['documentName'] as String? ?? 'Dokumen tanpa nama',
      chunkIndex: (json['chunkIndex'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      similarityScore: (json['similarityScore'] as num?)?.toDouble() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
    );
  }

  static List<MessageSource> listFrom(Object? raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(MessageSourceModel.fromJson)
        .toList(growable: false);
  }
}
