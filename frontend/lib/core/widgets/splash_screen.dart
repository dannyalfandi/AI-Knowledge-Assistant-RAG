import 'package:flutter/material.dart';

/// Shown while the app checks the stored session on startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const path = '/splash';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Knowledge Assistant', style: TextStyle(fontSize: 20)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
