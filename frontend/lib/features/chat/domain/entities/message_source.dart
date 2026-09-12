/// One retrieved chunk that grounded an assistant answer.
///
/// Both `POST /api/conversations/:id/ask` and `GET /api/conversations/:id`
/// return this shape, so a citation renders the same whether the answer just
/// arrived or the conversation was reopened later.
class MessageSource {
  const MessageSource({
    required this.documentChunkId,
    required this.documentId,
    required this.documentName,
    required this.chunkIndex,
    required this.content,
    required this.similarityScore,
    this.pageNumber,
  });

  final String documentChunkId;
  final String documentId;
  final String documentName;
  final int chunkIndex;

  /// The chunk text. Can be long, so the UI keeps it collapsed by default.
  final String content;

  final double similarityScore;

  /// Null when the extractor could not attribute the chunk to a page.
  final int? pageNumber;
}
