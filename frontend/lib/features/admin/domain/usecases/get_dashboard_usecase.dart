import '../entities/dashboard_summary.dart';
import '../repositories/admin_repository.dart';

/// Loads the aggregate counts shown on the admin dashboard.
class GetDashboardUseCase {
  const GetDashboardUseCase(this._repository);

  final AdminRepository _repository;

  Future<DashboardSummary> call() => _repository.getDashboard();
}
