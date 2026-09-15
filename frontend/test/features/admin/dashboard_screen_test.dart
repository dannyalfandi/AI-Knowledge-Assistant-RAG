import 'package:enterprise_knowledge_assistant/core/error/app_exception.dart';
import 'package:enterprise_knowledge_assistant/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/admin/domain/entities/dashboard_summary.dart';
import 'package:enterprise_knowledge_assistant/features/admin/domain/repositories/admin_repository.dart';
import 'package:enterprise_knowledge_assistant/features/admin/presentation/providers/dashboard_controller.dart';
import 'package:enterprise_knowledge_assistant/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardSummary _summary({
  int users = 12,
  int documents = 9,
  Map<DocumentStatus, int>? byStatus,
  int positive = 14,
  int negative = 6,
}) {
  return DashboardSummary(
    totalUsers: users,
    totalDocuments: documents,
    documentsByStatus:
        byStatus ??
        const {
          DocumentStatus.pending: 2,
          DocumentStatus.processing: 1,
          DocumentStatus.indexed: 5,
          DocumentStatus.failed: 1,
        },
    totalConversations: 31,
    questionsAsked: 87,
    questionsAnswered: 85,
    feedbackTotal: positive + negative,
    feedbackPositive: positive,
    feedbackNegative: negative,
    fetchedAt: DateTime(2026, 9, 12, 14, 30),
  );
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({this.summary});

  DashboardSummary? summary;
  Object? error;
  int calls = 0;

  @override
  Future<DashboardSummary> getDashboard() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return summary ?? _summary();
  }
}

/// Pumps a fixed number of frames rather than settling: the PROCESSING status
/// chip spins forever by design, so `pumpAndSettle` would never return.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  _FakeAdminRepository repository,
) async {
  // Tall enough for the whole dashboard to be laid out at once; at the default
  // 800x600 the ListView never builds the cards below the fold.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await _settle(tester);
}

void main() {
  group('rendering', () {
    testWidgets('shows the headline totals', (tester) async {
      await _pumpDashboard(tester, _FakeAdminRepository());

      expect(find.text('Pengguna'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Percakapan'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('85 terjawab'), findsOneWidget);
    });

    testWidgets('states when the snapshot was taken', (tester) async {
      await _pumpDashboard(tester, _FakeAdminRepository());

      // The dashboard is fetched, not polled, so it must say how old it is.
      expect(find.text('Diperbarui 14:30'), findsOneWidget);
    });

    testWidgets('breaks documents down in pipeline order, not by size', (
      tester,
    ) async {
      await _pumpDashboard(tester, _FakeAdminRepository());

      expect(find.text('Dokumen per status'), findsOneWidget);

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      // Waiting -> running -> done -> failed, so the list itself reads as the
      // pipeline rather than as a ranking.
      expect(labels.indexOf('Menunggu') < labels.indexOf('Diproses'), isTrue);
      expect(labels.indexOf('Diproses') < labels.indexOf('Terindeks'), isTrue);
      expect(labels.indexOf('Terindeks') < labels.indexOf('Gagal'), isTrue);
    });

    testWidgets('labels both feedback poles with a word and a number', (
      tester,
    ) async {
      await _pumpDashboard(tester, _FakeAdminRepository());

      // Identity never rests on colour alone.
      expect(find.text('Membantu'), findsOneWidget);
      expect(find.text('Kurang tepat'), findsOneWidget);
      expect(find.text('14 · 70%'), findsOneWidget);
      expect(find.text('6 · 30%'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    });
  });

  group('empty states', () {
    testWidgets('says so instead of drawing an empty document bar', (
      tester,
    ) async {
      final repository = _FakeAdminRepository(
        summary: _summary(
          documents: 0,
          byStatus: const {
            DocumentStatus.pending: 0,
            DocumentStatus.processing: 0,
            DocumentStatus.indexed: 0,
            DocumentStatus.failed: 0,
          },
        ),
      );

      await _pumpDashboard(tester, repository);

      expect(find.text('Belum ada dokumen yang diunggah.'), findsOneWidget);
      expect(find.text('Menunggu'), findsNothing);
    });

    testWidgets('says so instead of drawing an empty feedback bar', (
      tester,
    ) async {
      final repository = _FakeAdminRepository(
        summary: _summary(positive: 0, negative: 0),
      );

      await _pumpDashboard(tester, repository);

      expect(
        find.text('Belum ada jawaban yang dinilai pengguna.'),
        findsOneWidget,
      );
      expect(find.text('Membantu'), findsNothing);
    });
  });

  group('loading failure', () {
    testWidgets('shows the backend message with a retry', (tester) async {
      final repository = _FakeAdminRepository()
        ..error = const ForbiddenException('Forbidden');

      await _pumpDashboard(tester, repository);

      expect(find.text('Forbidden'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      repository.error = null;
      await tester.tap(find.text('Coba lagi'));
      await _settle(tester);

      expect(find.text('Pengguna'), findsOneWidget);
    });
  });

  group('refresh', () {
    testWidgets('re-fetches and keeps the numbers when it fails', (
      tester,
    ) async {
      final repository = _FakeAdminRepository();
      await _pumpDashboard(tester, repository);
      expect(repository.calls, 1);

      repository.error = const NetworkException();
      await tester.tap(find.byTooltip('Muat ulang'));
      await _settle(tester);

      expect(repository.calls, 2);
      // Stale numbers are still the last known truth, so they stay on screen
      // and the failure goes to a snack bar.
      expect(find.text('Pengguna'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('controller', () {
    test('does not poll: it fetches once per open', () async {
      final repository = _FakeAdminRepository();
      final container = ProviderContainer(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.listen(dashboardControllerProvider, (_, _) {});
      await container.read(dashboardControllerProvider.future);

      expect(repository.calls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(repository.calls, 1);
    });
  });
}
