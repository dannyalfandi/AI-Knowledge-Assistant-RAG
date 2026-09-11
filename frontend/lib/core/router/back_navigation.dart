import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Goes back one step, falling back to [fallbackLocation] when there is nothing
/// to pop.
///
/// On the web a screen is often the *first* entry in the stack — the URL was
/// typed, bookmarked, or reloaded — so `context.pop()` alone would leave the
/// user stranded. Falling back to an explicit location keeps a back button
/// meaningful in both cases.
void popOrGo(BuildContext context, String fallbackLocation) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallbackLocation);
}

/// AppBar leading button wired to [popOrGo].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.fallbackLocation,
    this.tooltip = 'Kembali',
  });

  /// Where to go when the navigation stack has nothing to pop.
  final String fallbackLocation;

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => popOrGo(context, fallbackLocation),
      icon: const Icon(Icons.arrow_back),
      tooltip: tooltip,
    );
  }
}
