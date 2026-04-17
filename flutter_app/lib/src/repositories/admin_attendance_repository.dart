import '../core/network/api_client.dart';
import '../models/admin_attendance_overview.dart';
import '../models/admin_monthly_attendance_overview.dart';

class AdminAttendanceRepository {
  const AdminAttendanceRepository(this._client);

  final ApiClient _client;

  Future<AdminAttendanceOverview> fetchOverview({
    DateTime? date,
    String? search,
    int? departmentId,
    String? status,
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (date != null) 'date': _formatDate(date),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null) 'department_id': '$departmentId',
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _client.get(
      '/admin/attendance-overview',
      queryParameters: query,
    );

    return AdminAttendanceOverview.fromJson(response);
  }

  Future<AdminMonthlyAttendanceOverview> fetchMonthlyOverview({
    DateTime? month,
    String? search,
    int? departmentId,
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (month != null) 'month': _formatMonth(month),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null) 'department_id': '$departmentId',
    };

    final response = await _client.get(
      '/admin/monthly-attendance',
      queryParameters: query,
    );

    return AdminMonthlyAttendanceOverview.fromJson(response);
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatMonth(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
