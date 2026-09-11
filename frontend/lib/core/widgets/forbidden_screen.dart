import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';

/// Shown when a signed-in user reaches a route their role does not allow —
/// today that means a non-ADMIN opening `/documents` (typing the URL directly
/// is easy on Flutter Web).
///
/// This is a UX affordance, not a security boundary: the backend's
/// `authorize("ADMIN")` middleware remains the real gate.
class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  static const path = '/forbidden';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tidak Berwenang')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Akses ditolak',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Halaman ini hanya untuk administrator. Hubungi admin jika '
                  'Anda merasa seharusnya punya akses.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => context.go(HomeScreen.path),
                  child: const Text('Kembali ke beranda'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
