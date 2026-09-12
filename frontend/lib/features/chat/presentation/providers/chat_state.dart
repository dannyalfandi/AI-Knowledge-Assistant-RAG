import '../../domain/entities/message.dart';

/// A question that has been submitted but has no stored answer yet.
///
/// It lives outside [ChatState.messages] because the backend only persists a
/// question together with its answer: until `/ask` succeeds, this question
/// exists solely on the client. Keeping it here is what guarantees a failed
/// question stays visible instead of vanishing.
class PendingAsk {
  const PendingAsk({
    required this.question,
    required this.isSending,
    this.errorMessage,
  });

  const PendingAsk.sending(String question)
    : this(question: question, isSending: true);

  const PendingAsk.failed({required String question, required String message})
    : this(question: question, isSending: false, errorMessage: message);

  final String question;

  /// The request is in flight: show the typing indicator, disable the input.
  final bool isSending;

  /// Set when `/ask` failed; the UI offers a retry.
  final String? errorMessage;

  bool get hasFailed => errorMessage != null;
}

/// Everything one conversation screen renders.
class ChatState {
  const ChatState({required this.messages, this.title, this.pending});

  /// Stored history, oldest first.
  final List<Message> messages;

  final String? title;

  /// Null while idle. Non-null while a question is being answered or after it
  /// failed.
  final PendingAsk? pending;

  bool get isAwaitingAnswer => pending?.isSending ?? false;

  bool get isEmpty => messages.isEmpty && pending == null;

  ChatState copyWith({
    List<Message>? messages,
    String? title,
    PendingAsk? pending,
    bool clearPending = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      title: title ?? this.title,
      pending: clearPending ? null : pending ?? this.pending,
    );
  }
}
