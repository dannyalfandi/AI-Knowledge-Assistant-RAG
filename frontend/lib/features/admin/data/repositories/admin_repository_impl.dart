import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required this.remote});

  final AdminRemoteDataSource remote;

  @override
  Future<DashboardSummary> getDashboard() => remote.getDashboard();
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(remote: ref.watch(adminRemoteDataSourceProvider));
});
