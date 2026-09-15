import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_controller.dart';
import '../widgets/document_status_breakdown.dart';
import '../widgets/feedback_split_bar.dart';
import '../widgets/stat_tile.dart';
import '../widgets/stat_tile_grid.dart';

/// ADMIN-only overview of the knowledge base: headline totals, the document
/// pipeline, and how users are rating the answers.
///
/// Fetched on open and on demand rather than polled — see [DashboardController]
/// for why — so the header states how old the numbers are.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const path = '/admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: const AppBackButton(fallbackLocation: HomeScreen.path),
        actions: [
          IconButton(
            onPressed: () => _refresh(context, ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat dashboard.',
          onRetry: controller.refresh,
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () => _refresh(context, ref),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UpdatedAt(fetchedAt: summary.fetchedAt),
              const SizedBox(height: 16),
              StatTileGrid(
                tiles: [
                  StatTile(
                    label: 'Pengguna',
                    value: summary.totalUsers,
                    icon: Icons.people_outline,
                  ),
                  StatTile(
                    label: 'Percakapan',
                    value: summary.totalConversations,
                    icon: Icons.forum_outlined,
                  ),
                  StatTile(
                    label: 'Pertanyaan',
                    value: summary.questionsAsked,
                    icon: Icons.help_outline,
                    caption: _answeredCaption(summary),
                  ),
                  StatTile(
                    label: 'Dokumen',
                    value: summary.totalDocuments,
                    icon: Icons.description_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DocumentStatusBreakdown(summary: summary),
              const SizedBox(height: 16),
              FeedbackSplitBar(summary: summary),
            ],
          ),
        ),
      ),
    );
  }

  /// Questions are only useful next to how many got an answer — a gap between
  /// the two means answers failed somewhere.
  static String _answeredCaption(DashboardSummary summary) {
    if (summary.questionsAsked == 0) return 'Belum ada pertanyaan';
    return '${formatCount(summary.questionsAnswered)} terjawab';
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(dashboardControllerProvider.notifier).refresh();
    } on AppException catch (error) {
      // The previous numbers are still on screen, so the failure belongs in a
      // snack bar rather than replacing the dashboard with an error page.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _UpdatedAt extends StatelessWidget {
  const _UpdatedAt({required this.fetchedAt});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String two(int n) => n.toString().padLeft(2, '0');

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          'Diperbarui ${two(fetchedAt.hour)}:${two(fetchedAt.minute)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
