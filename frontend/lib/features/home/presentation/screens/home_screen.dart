import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../documents/presentation/screens/documents_screen.dart';

/// Landing screen for a signed-in user. Admin-only entry points are rendered
/// only for ADMIN accounts; the router guard and the backend both enforce the
/// same rule for anyone who reaches the route another way.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user == null
                      ? 'Masuk sebagai —'
                      : 'Masuk sebagai '
                            '${user.name.isEmpty ? user.email : user.name} '
                            '(${user.role})',
                  textAlign: TextAlign.center,
                ),
                if (user?.isAdmin ?? false) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(DocumentsScreen.path),
                    icon: const Icon(Icons.folder_copy_outlined),
                    label: const Text('Kelola Dokumen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
