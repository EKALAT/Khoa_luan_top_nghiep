import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/department_option.dart';

class AdminDepartmentRepository {
  const AdminDepartmentRepository(this._client);

  final ApiClient _client;

  Future<(String, DepartmentOption)> createDepartment({
    required String name,
    required String code,
    String? description,
    required double monthlySalary,
    required bool isActive,
  }) async {
    final response = await _client.post(
      '/admin/departments',
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
      DepartmentOption.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, DepartmentOption)> updateDepartment({
    required int departmentId,
    String? name,
    String? code,
    String? description,
    double? monthlySalary,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (code != null) body['code'] = code;
    if (description != null) body['description'] = description;
    if (monthlySalary != null) body['monthly_salary'] = monthlySalary;
    if (isActive != null) body['is_active'] = isActive;

    final response = await _client.put(
      '/admin/departments/$departmentId',
      body: body,
    );

    return (
      asString(response['message']) ?? 'Cap nhat phong ban thanh cong.',
      DepartmentOption.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, DepartmentOption)> updateDepartmentSalary(
    int departmentId, {
    required double monthlySalary,
  }) async {
    return updateDepartment(
      departmentId: departmentId,
      monthlySalary: monthlySalary,
    );
  }
}
