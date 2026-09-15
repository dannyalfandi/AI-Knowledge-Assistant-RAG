import '../entities/dashboard_summary.dart';

/// Contract for the ADMIN-only dashboard endpoint. Throws an [AppException] on
/// failure — `ForbiddenException` when a non-ADMIN somehow reaches it.
abstract interface class AdminRepository {
  Future<DashboardSummary> getDashboard();
}
