import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/conversation.dart';
import '../providers/conversations_controller.dart';
import '../widgets/conversation_list_tile.dart';
import 'chat_screen.dart';

/// The signed-in user's conversations, most recent activity first.
class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  static const path = '/conversations';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsControllerProvider);
    final controller = ref.read(conversationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Percakapan'),
        leading: const AppBackButton(fallbackLocation: HomeScreen.path),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewChat(context, ref),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Chat Baru'),
      ),
      body: conversationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat daftar percakapan.',
          onRetry: controller.refresh,
        ),
        data: (state) {
          if (state.conversations.isEmpty) return const _EmptyView();

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: state.conversations.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.conversations.length) {
                  return _LoadMoreTile(
                    isLoading: state.isLoadingMore,
                    onLoadMore: () => _loadMore(context, ref),
                  );
                }

                final conversation = state.conversations[index];

                return ConversationListTile(
                  conversation: conversation,
                  onTap: () => context.go(ChatScreen.pathFor(conversation.id)),
                  onDelete: () => _delete(context, ref, conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    try {
      // An empty conversation is created up front, so the chat screen always
      // has a real id to ask against.
      final conversation = await ref
          .read(conversationsControllerProvider.notifier)
          .createConversation();

      if (context.mounted) context.go(ChatScreen.pathFor(conversation.id));
    } on AppException catch (error) {
      if (context.mounted) _notify(context, error.message, isError: true);
    }
  }

  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(conversationsControllerProvider.notifier).loadMore();
    } on AppException catch (error) {
      if (context.mounted) _notify(context, error.message, isError: true);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Hapus percakapan?',
      message:
          '"${conversation.title ?? 'Percakapan tanpa judul'}" beserta seluruh '
          'pesan dan sitasinya akan dihapus permanen. Tindakan ini tidak bisa '
          'dibatalkan.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(conversationsControllerProvider.notifier)
          .delete(conversation.id);
      if (context.mounted) _notify(context, 'Percakapan dihapus.');
    } on AppException catch (error) {
      if (context.mounted) _notify(context, error.message, isError: true);
    }
  }
}

void _notify(BuildContext context, String message, {bool isError = false}) {
  final colors = Theme.of(context).colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colors.error : null,
    ),
  );
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.isLoading, required this.onLoadMore});

  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: onLoadMore,
                child: const Text('Muat lebih banyak'),
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
              Icons.forum_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Belum ada percakapan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Mulai chat baru untuk bertanya tentang dokumen internal '
              'perusahaan.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
