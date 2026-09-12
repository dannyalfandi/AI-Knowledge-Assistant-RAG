/// Who produced a message, mirroring the backend `MessageRole` enum.
enum MessageRole {
  user,
  assistant,

  /// A role this client does not know yet; rendered like an assistant message
  /// rather than dropped.
  unknown;

  bool get isUser => this == MessageRole.user;
}
