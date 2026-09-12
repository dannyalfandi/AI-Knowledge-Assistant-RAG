import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/conversation.dart';
import 'chat_providers.dart';

/// The conversation list plus where it is in the backend's pagination.
class ConversationsState {
  const ConversationsState({
    required this.conversations,
    required this.page,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  final List<Conversation> conversations;
  final int page;
  final int totalPages;

  /// A "load more" request is in flight; the list below stays visible.
  final bool isLoadingMore;

  bool get hasMore => page < totalPages;

  ConversationsState copyWith({
    List<Conversation>? conversations,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Owns the signed-in user's conversation list, ordered by most recent
/// activity (the backend sorts by `updatedAt`).
class ConversationsController extends AsyncNotifier<ConversationsState> {
  ConversationsState? _current;

  @override
  Future<ConversationsState> build() async {
    _current = null;

    final page = await ref
        .read(listConversationsUseCaseProvider)
        .call(page: 1, limit: conversationsPageSize);

    final initial = ConversationsState(
      conversations: page.conversations,
      page: page.page,
      totalPages: page.totalPages,
    );

    _current = initial;
    return initial;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Appends the next page. Does nothing when there is none, or while another
  /// page is already loading.
  Future<void> loadMore() async {
    final current = _current;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    _emit(current.copyWith(isLoadingMore: true));

    try {
      final next = await ref
          .read(listConversationsUseCaseProvider)
          .call(page: current.page + 1, limit: conversationsPageSize);

      final latest = _current ?? current;
      _emit(
        latest.copyWith(
          conversations: [...latest.conversations, ...next.conversations],
          page: next.page,
          totalPages: next.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final latest = _current;
      if (latest != null) _emit(latest.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Creates an empty conversation and puts it at the top of the list, so the
  /// screen can navigate straight into it.
  Future<Conversation> createConversation() async {
    final conversation = await ref
        .read(createConversationUseCaseProvider)
        .call();

    final current = _current;
    if (current != null) {
      _emit(
        current.copyWith(
          conversations: [conversation, ...current.conversations],
        ),
      );
    }

    return conversation;
  }

  /// Deletes on the backend first, then drops the row. Rethrows on failure so
  /// the screen can report it; nothing is removed optimistically.
  Future<void> delete(String id) async {
    await ref.read(deleteConversationUseCaseProvider).call(id);

    final current = _current;
    if (current == null) return;

    _emit(
      current.copyWith(
        conversations: current.conversations
            .where((conversation) => conversation.id != id)
            .toList(growable: false),
      ),
    );
  }

  void _emit(ConversationsState next) {
    _current = next;
    state = AsyncData(next);
  }
}

/// Retry is disabled for the same reason as the documents providers: the
/// screen surfaces the error with a retry button, so a background exponential
/// retry would only repeat a failing request.
final conversationsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      ConversationsController,
      ConversationsState
    >(ConversationsController.new, retry: (_, _) => null);
