import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/admin_department_salary.dart';
import '../models/admin_payroll_overview.dart';

class AdminPayrollRepository {
  const AdminPayrollRepository(this._client);

  final ApiClient _client;

  Future<List<AdminDepartmentSalary>> fetchDepartmentSalaries() async {
    final response = await _client.get('/admin/department-salaries');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];

    return items
        .map(
          (item) => AdminDepartmentSalary.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<(String, AdminDepartmentSalary)> createDepartmentSalary({
    required String name,
    required String code,
    String? description,
    required double monthlySalary,
    required bool isActive,
  }) async {
    final response = await _client.post(
      '/admin/department-salaries',
      body: <String, dynamic>{
        'name': name,
        'code': code,
        'description': description,
        'monthly_salary': monthlySalary,
        'is_active': isActive,
      },
    );

    return (
      asString(response['message']) ?? 'Tao phong ban thanh cong.',
      AdminDepartmentSalary.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  Future<(String, AdminDepartmentSalary)> updateDepartmentSalary(
    int departmentId, {
    required String name,
    required String code,
    String? description,
    required double monthlySalary,
    required bool isActive,
  }) async {
    final response = await _client.put(
      '/admin/department-salaries/$departmentId',
      body: <String, dynamic>{
        'name': name,
        'code': code,
        'description': description,
        'monthly_salary': monthlySalary,
        'is_active': isActive,
      },
    );

    return (
      asString(response['message']) ?? 'Cap nhat phong ban thanh cong.',
      AdminDepartmentSalary.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      ),
    );
  }

  Future<String> deleteDepartmentSalary(int departmentId) async {
    final response = await _client.delete('/admin/department-salaries/$departmentId');
    return asString(response['message']) ?? 'Xoa phong ban thanh cong.';
  }

  Future<AdminPayrollOverview> fetchMonthlyPayroll({
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
      '/admin/monthly-payroll',
      queryParameters: query,
    );

    return AdminPayrollOverview.fromJson(response);
  }

  Future<List<int>> exportMonthlyPayrollCsv({
    DateTime? month,
    String? search,
    int? departmentId,
  }) {
    final query = <String, String>{
      if (month != null) 'month': _formatMonth(month),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (departmentId != null) 'department_id': '$departmentId',
    };

    return _client.getBytes(
      '/admin/monthly-payroll/export',
      queryParameters: query,
    );
  }

  String _formatMonth(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
