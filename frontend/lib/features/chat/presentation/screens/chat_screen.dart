import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/back_navigation.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/failed_ask_bubble.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator_bubble.dart';
import 'conversation_list_screen.dart';

/// One conversation: its history, the question being answered, and the input.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  /// Sub-route segment nested under [ConversationListScreen.path], which makes
  /// the full route `/conversations/:id`.
  static const routeSegment = ':id';

  static String pathFor(String id) => '/conversations/$id';

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  /// How close to the bottom still counts as "following the conversation".
  static const _stickThreshold = 80.0;

  final _scrollController = ScrollController();

  /// True while the user is at (or near) the latest message. Only then may new
  /// content scroll the view — reading older history is never interrupted.
  bool _pinnedToBottom = true;

  /// Something arrived while the user was reading further up.
  bool _hasUnseenMessages = false;

  int _renderedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final pinned =
        position.maxScrollExtent - position.pixels <= _stickThreshold;

    if (pinned == _pinnedToBottom && !(pinned && _hasUnseenMessages)) return;

    setState(() {
      _pinnedToBottom = pinned;
      if (pinned) _hasUnseenMessages = false;
    });
  }

  /// Scrolls to the newest message after the list has laid out the new item,
  /// so `maxScrollExtent` already accounts for it.
  void _scrollToBottom({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  /// Decides what a newly rendered item does to the scroll position: follow it
  /// when the user is already at the bottom, otherwise leave the view alone and
  /// offer a jump button instead.
  void _handleItemCountChange(int itemCount) {
    final isFirstLayout = _renderedItemCount == 0;
    final grew = itemCount > _renderedItemCount;
    _renderedItemCount = itemCount;

    if (!grew) return;

    if (isFirstLayout) {
      // Opening a conversation starts at the latest message, without animating
      // through the whole history.
      _scrollToBottom(animate: false);
      return;
    }

    if (_pinnedToBottom) {
      _scrollToBottom(animate: true);
    } else if (!_hasUnseenMessages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasUnseenMessages = true);
      });
    }
  }

  Future<void> _send(String question) async {
    // The user's own send is an explicit intent to watch the answer, so this
    // scrolls even if they were reading further up.
    setState(() {
      _pinnedToBottom = true;
      _hasUnseenMessages = false;
    });
    _scrollToBottom(animate: true);

    await ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final provider = chatControllerProvider(widget.conversationId);
    final chatState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(chatState.value?.title ?? 'Percakapan'),
        leading: const AppBackButton(
          fallbackLocation: ConversationListScreen.path,
        ),
      ),
      body: chatState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ChatErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat percakapan.',
          onRetry: controller.refresh,
        ),
        data: (state) => Column(
          children: [
            Expanded(child: _buildBody(state, controller)),
            ChatInputBar(enabled: !state.isAwaitingAnswer, onSubmit: _send),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChatState state, ChatController controller) {
    if (state.isEmpty) {
      _renderedItemCount = 0;
      return const _EmptyConversationView();
    }

    // Stored history, then the pending question, then either the typing
    // indicator or the failure bubble.
    final items = <Widget>[
      for (final message in state.messages)
        MessageBubble(message: message, conversationId: widget.conversationId),
      if (state.pending case final pending?) ...[
        PendingQuestionBubble(question: pending.question),
        if (pending.isSending)
          const TypingIndicatorBubble()
        else if (pending.hasFailed)
          FailedAskBubble(
            message: pending.errorMessage!,
            onRetry: controller.retryPending,
            onDismiss: controller.dismissPending,
          ),
      ],
    ];

    _handleItemCountChange(items.length);

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
        if (_hasUnseenMessages)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _pinnedToBottom = true;
                  _hasUnseenMessages = false;
                });
                _scrollToBottom(animate: true);
              },
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Pesan baru'),
            ),
          ),
      ],
    );
  }
}

class _EmptyConversationView extends StatelessWidget {
  const _EmptyConversationView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Mulai bertanya', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Jawaban disusun dari dokumen yang sudah terindeks, lengkap '
              'dengan sumbernya.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatErrorView extends StatelessWidget {
  const _ChatErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
