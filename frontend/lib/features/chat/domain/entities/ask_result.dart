import 'message.dart';

/// The outcome of `POST /api/conversations/:id/ask`: the question and the
/// grounded answer, both already persisted by the backend.
class AskResult {
  const AskResult({required this.userMessage, required this.assistantMessage});

  final Message userMessage;

  /// Carries the retrieved chunks as its sources.
  final Message assistantMessage;
}
