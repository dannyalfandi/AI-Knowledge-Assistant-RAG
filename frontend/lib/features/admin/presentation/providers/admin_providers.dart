import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';

/// Use-case wiring, kept separate from the controller (same split as the other
/// features' `*_providers.dart`).
final getDashboardUseCaseProvider = Provider<GetDashboardUseCase>((ref) {
  return GetDashboardUseCase(ref.watch(adminRepositoryProvider));
});
