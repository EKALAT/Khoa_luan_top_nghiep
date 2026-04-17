import '../core/network/api_client.dart';
import '../models/admin_payroll_overview.dart';

class AdminPayrollRepository {
  const AdminPayrollRepository(this._client);

  final ApiClient _client;

  Future<AdminPayrollOverview> fetchOverview({
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

    final response = await _client.get('/admin/payroll', queryParameters: query);
    return AdminPayrollOverview.fromJson(response);
  }

  Future<List<int>> exportCsv({
    DateTime? month,
    String? search,
    int? departmentId,
  }) {
    final query = <String, String>{
      if (month != null) 'month': _formatMonth(month),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null) 'department_id': '$departmentId',
    };

    return _client.getBytes('/admin/payroll/export', queryParameters: query);
  }

  String _formatMonth(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
