/// Processing lifecycle of a document, mirroring the backend `DocumentStatus`
/// enum (`PENDING` → `PROCESSING` → `INDEXED`, or `FAILED`).
enum DocumentStatus {
  pending,
  processing,
  indexed,
  failed,

  /// A status the backend introduced that this client does not know yet. Kept
  /// so an unexpected value degrades gracefully instead of throwing.
  unknown;

  /// Only these two may be (re)processed — the backend rejects a `PROCESSING`
  /// document with 409, and re-running an `INDEXED` one is a deliberate
  /// re-index rather than part of the normal admin flow.
  bool get isProcessable =>
      this == DocumentStatus.pending || this == DocumentStatus.failed;
}
