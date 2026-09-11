import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';

/// Placeholder landing screen for a signed-in user. Real feature screens
/// (documents, chat, ...) come in later Fase 5 tahaps.
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
        child: Text(
          user == null
              ? 'Masuk sebagai —'
              : 'Masuk sebagai ${user.name.isEmpty ? user.email : user.name} '
                  '(${user.role})',
        ),
      ),
    );
  }
}
