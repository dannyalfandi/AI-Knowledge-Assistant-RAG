import '../../domain/entities/document.dart';

/// What the documents list screen renders.
///
/// The list is wrapped in a small state object rather than exposed as a bare
/// `List<Document>` so a background poll can refresh the data without flipping
/// the provider back to `AsyncLoading` (which would blank the screen), and so
/// the screen can tell the user when automatic refreshing stopped.
class DocumentsState {
  const DocumentsState({
    required this.documents,
    this.isRefreshing = false,
    this.pollingStoppedMessage,
  });

  final List<Document> documents;

  /// A silent refresh is in flight; the list below stays visible.
  final bool isRefreshing;

  /// Set when automatic refreshing gave up (took too long, or the backend kept
  /// failing). `null` while polling is healthy or idle.
  final String? pollingStoppedMessage;

  bool get hasProcessing => documents.any((document) => document.isProcessing);

  DocumentsState copyWith({
    List<Document>? documents,
    bool? isRefreshing,
    String? pollingStoppedMessage,
    bool clearPollingStoppedMessage = false,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pollingStoppedMessage: clearPollingStoppedMessage
          ? null
          : pollingStoppedMessage ?? this.pollingStoppedMessage,
    );
  }
}
