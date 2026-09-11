import 'package:enterprise_knowledge_assistant/core/router/back_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _screen(String title, {String? backTo}) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: backTo == null
          ? null
          : AppBackButton(fallbackLocation: backTo),
    ),
  );
}

GoRouter _router(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, _) => _screen('Beranda')),
      GoRoute(
        path: '/documents',
        builder: (_, _) => _screen('Dokumen', backTo: '/'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, _) => _screen('Detail', backTo: '/documents'),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('back from /documents reaches home when nothing can be popped', (
    tester,
  ) async {
    final router = _router('/documents');
    await _pumpRouter(tester, router);

    expect(find.text('Dokumen'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('back from a deep-linked detail falls back to the list', (
    tester,
  ) async {
    // Opening /documents/doc-1 directly is the web reload / shared-link case.
    final router = _router('/documents/doc-1');
    await _pumpRouter(tester, router);

    expect(find.text('Detail'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Dokumen'), findsOneWidget);
  });

  testWidgets('back pops the stack when the detail was opened from the list', (
    tester,
  ) async {
    final router = _router('/documents');
    await _pumpRouter(tester, router);

    router.push('/documents/doc-1');
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Dokumen'), findsOneWidget);
  });
}
