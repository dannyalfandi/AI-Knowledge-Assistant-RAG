import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_summary.dart';
import 'admin_providers.dart';

/// Loads the dashboard once when the screen opens, and again whenever the admin
/// asks for it.
///
/// Deliberately not polled: unlike a document stuck in `PROCESSING`, these
/// totals have no moment when they are known to change, so a timer would query
/// the backend forever with no stop condition for numbers that are seconds
/// fresher. The screen instead shows when the snapshot was taken and offers a
/// refresh.
class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    return ref.read(getDashboardUseCaseProvider).call();
  }

  /// Reloads, keeping the current numbers on screen until the new ones arrive
  /// so a refresh does not blank the dashboard.
  ///
  /// Rethrows on failure — with numbers already on screen the error belongs in
  /// a snack bar, not in place of the dashboard, so the caller decides how to
  /// show it. Stale numbers are kept: they are still the last known truth.
  Future<void> refresh() async {
    final previous = state.value;

    try {
      final summary = await ref.read(getDashboardUseCaseProvider).call();
      state = AsyncData(summary);
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
      rethrow;
    }
  }
}

/// Retry is disabled, matching the other feature controllers: the screen shows
/// the error with its own retry button, so Riverpod's exponential retry would
/// only repeat a failing request in the background.
final dashboardControllerProvider =
    AsyncNotifierProvider.autoDispose<DashboardController, DashboardSummary>(
      DashboardController.new,
      retry: (_, _) => null,
    );
