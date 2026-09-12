import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/message_feedback.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/entities/message.dart';
import 'chat_providers.dart';
import 'chat_state.dart';
import 'conversations_controller.dart';

/// Owns one conversation: its message history and the state of the question
/// currently being answered.
///
/// Keyed by conversation id, so "waiting for an answer" is scoped to a single
/// conversation — the user can open another one and ask there while the first
/// is still thinking.
class ChatController extends AsyncNotifier<ChatState> {
  ChatController(this.conversationId);

  final String conversationId;

  ChatState? _current;

  @override
  Future<ChatState> build() async {
    // Carry an in-flight question across a rebuild; `build` re-runs on refresh,
    // and dropping the pending state would make the question disappear.
    final carriedPending = _current?.pending;
    _current = null;

    final detail = await ref
        .read(getConversationUseCaseProvider)
        .call(conversationId);

    final initial = ChatState(
      messages: detail.messages,
      title: detail.title,
      pending: carriedPending,
    );

    _current = initial;
    return initial;
  }

  /// Sends [question] through the RAG pipeline.
  ///
  /// The question is shown immediately as a pending bubble; on success the
  /// backend's stored question and answer replace it, and on failure it stays
  /// on screen with a retry affordance — it is never silently dropped.
  Future<void> ask(String question) async {
    final trimmed = question.trim();
    final current = _current;
    if (trimmed.isEmpty || current == null || current.isAwaitingAnswer) return;

    _emit(current.copyWith(pending: PendingAsk.sending(trimmed)));

    // The provider is auto-dispose: without this the controller (and the
    // in-flight request's result) would be thrown away the moment the user
    // navigates back to the conversation list mid-answer.
    final link = ref.keepAlive();

    try {
      final result = await ref
          .read(askQuestionUseCaseProvider)
          .call(conversationId: conversationId, question: trimmed);

      final latest = _current;
      if (latest == null) return;

      _emit(
        latest.copyWith(
          messages: <Message>[
            ...latest.messages,
            result.userMessage,
            result.assistantMessage,
          ],
          clearPending: true,
        ),
      );

      // The list is ordered by updatedAt and shows a message count, both of
      // which just changed.
      ref.invalidate(conversationsControllerProvider);
    } on AppException catch (error) {
      _failPending(trimmed, error.message);
    } catch (_) {
      _failPending(trimmed, 'Gagal mengirim pertanyaan. Coba lagi.');
    } finally {
      link.close();
    }
  }

  /// Re-sends the question that failed. Safe to call repeatedly: the backend
  /// stores a question only together with its answer, so a failed attempt
  /// leaves nothing behind to duplicate.
  Future<void> retryPending() async {
    final pending = _current?.pending;
    if (pending == null || pending.isSending) return;

    return ask(pending.question);
  }

  /// Rates an assistant answer, optionally with a comment.
  ///
  /// The icon flips immediately and rolls back if the request fails, so it can
  /// never sit in a state the backend does not agree with. Re-selecting the
  /// rating a message already has is a no-op: the backend has no delete
  /// endpoint, so it could neither be withdrawn nor meaningfully re-sent.
  ///
  /// Omitting [comment] leaves an existing comment untouched on the backend.
  /// Rethrows on failure so the screen can show the message.
  Future<void> submitFeedback(
    String messageId, {
    required FeedbackType type,
    String? comment,
  }) async {
    final current = _current;
    if (current == null) return;

    final index = current.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index == -1) return;

    final target = current.messages[index];
    if (!target.canReceiveFeedback) return;

    final isUnchanged = target.myFeedback?.type == type && comment == null;
    if (isUnchanged) return;

    final previous = target.myFeedback;

    // Optimistic: show the new rating right away, but keep the old one so the
    // icon can be put back exactly as it was if the request fails.
    _replaceMessage(
      index,
      target.copyWithFeedback(
        MessageFeedback(
          id: previous?.id ?? '',
          type: type,
          comment: comment ?? previous?.comment,
          createdAt: previous?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );

    try {
      final saved = await ref
          .read(submitFeedbackUseCaseProvider)
          .call(messageId: messageId, type: type, comment: comment);

      final latest = _current;
      if (latest == null) return;

      final savedIndex = latest.messages.indexWhere(
        (message) => message.id == messageId,
      );
      if (savedIndex == -1) return;

      _replaceMessage(
        savedIndex,
        latest.messages[savedIndex].copyWithFeedback(saved),
      );
    } catch (_) {
      final latest = _current;
      if (latest != null) {
        final revertIndex = latest.messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (revertIndex != -1) {
          _replaceMessage(
            revertIndex,
            latest.messages[revertIndex].copyWithFeedback(previous),
          );
        }
      }
      rethrow;
    }
  }

  void _replaceMessage(int index, Message message) {
    final current = _current;
    if (current == null) return;

    final messages = [...current.messages];
    messages[index] = message;
    _emit(current.copyWith(messages: messages));
  }

  /// Drops a failed question without re-sending it.
  void dismissPending() {
    final current = _current;
    if (current == null || current.isAwaitingAnswer) return;

    _emit(current.copyWith(clearPending: true));
  }

  /// Reloads the history from the backend, keeping any in-flight question.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  void _failPending(String question, String message) {
    final latest = _current;
    if (latest == null) return;

    _emit(
      latest.copyWith(
        pending: PendingAsk.failed(question: question, message: message),
      ),
    );
  }

  void _emit(ChatState next) {
    _current = next;
    state = AsyncData(next);
  }
}

/// Retry is disabled: a failed load shows an error with a retry button, and
/// Riverpod's default exponential retry would otherwise keep re-requesting a
/// 404 (a conversation that was deleted or belongs to someone else).
final chatControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(
      ChatController.new,
      retry: (_, _) => null,
    );
