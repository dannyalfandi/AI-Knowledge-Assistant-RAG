import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/dio_provider.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../models/dashboard_summary_model.dart';

/// Talks to `GET /api/admin/dashboard`, which the backend gates with
/// `authorize("ADMIN")`.
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DashboardSummaryModel> getDashboard() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/dashboard');

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const UnknownException('Respons server tidak sesuai format.');
      }

      return DashboardSummaryModel.fromJson(data);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(dioProvider));
});
