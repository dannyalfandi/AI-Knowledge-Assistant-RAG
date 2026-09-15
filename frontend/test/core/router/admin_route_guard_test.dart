import 'package:enterprise_knowledge_assistant/core/router/app_router.dart';
import 'package:enterprise_knowledge_assistant/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:enterprise_knowledge_assistant/features/admin/domain/entities/dashboard_summary.dart';
import 'package:enterprise_knowledge_assistant/features/admin/domain/repositories/admin_repository.dart';
import 'package:enterprise_knowledge_assistant/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:enterprise_knowledge_assistant/features/auth/domain/entities/user.dart';
import 'package:enterprise_knowledge_assistant/features/auth/presentation/providers/auth_controller.dart';
import 'package:enterprise_knowledge_assistant/features/documents/domain/entities/document_status.dart';
import 'package:enterprise_knowledge_assistant/features/documents/presentation/screens/documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = User(
  id: 'u1',
  email: 'admin@corp.com',
  name: 'Admin',
  role: 'ADMIN',
);

const _user = User(
  id: 'u2',
  email: 'staff@corp.com',
  name: 'Staff',
  role: 'USER',
);

class _FakeAuthController extends AuthController {
  _FakeAuthController(this.user);

  final User? user;

  @override
  Future<User?> build() async => user;
}

class _StubAdminRepository implements AdminRepository {
  @override
  Future<DashboardSummary> getDashboard() async {
    return DashboardSummary(
      totalUsers: 1,
      totalDocuments: 0,
      documentsByStatus: const {
        DocumentStatus.pending: 0,
        DocumentStatus.processing: 0,
        DocumentStatus.indexed: 0,
        DocumentStatus.failed: 0,
      },
      totalConversations: 0,
      questionsAsked: 0,
      questionsAnswered: 0,
      feedbackTotal: 0,
      feedbackPositive: 0,
      feedbackNegative: 0,
      fetchedAt: DateTime(2026, 9, 12, 14, 30),
    );
  }
}

Future<void> _pumpAt(
  WidgetTester tester, {
  required User signedInAs,
  required String location,
}) async {
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _FakeAuthController(signedInAs),
      ),
      adminRepositoryProvider.overrideWithValue(_StubAdminRepository()),
    ],
  );
  addTearDown(container.dispose);

  // Resolve the session before the router reads it, so the guard does not run
  // against a still-loading auth state.
  await container.read(authControllerProvider.future);

  final router = container.read(routerProvider);
  addTearDown(router.dispose);

  router.go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('an admin reaches the dashboard', (tester) async {
    await _pumpAt(tester, signedInAs: _admin, location: DashboardScreen.path);

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Akses ditolak'), findsNothing);
  });

  testWidgets('a non-admin typing /admin is refused, not redirected silently', (
    tester,
  ) async {
    await _pumpAt(tester, signedInAs: _user, location: DashboardScreen.path);

    expect(find.text('Akses ditolak'), findsOneWidget);
  });

  testWidgets('the documents guard still holds after the prefix refactor', (
    tester,
  ) async {
    await _pumpAt(tester, signedInAs: _user, location: DocumentsScreen.path);

    expect(find.text('Akses ditolak'), findsOneWidget);
  });

  testWidgets('an admin is not stranded on the refusal page', (tester) async {
    await _pumpAt(tester, signedInAs: _admin, location: '/forbidden');

    expect(find.text('Akses ditolak'), findsNothing);
    expect(find.text('Beranda'), findsWidgets);
  });
}
