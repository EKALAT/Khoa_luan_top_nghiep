import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/admin_user.dart';
import '../models/paginated_response.dart';

class AdminUserRepository {
  const AdminUserRepository(this._client);

  final ApiClient _client;

  Future<PaginatedResponse<AdminUser>> fetchUsers({
    int page = 1,
    String? search,
    String? roleCode,
    bool? isActive,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (roleCode != null && roleCode.isNotEmpty) 'role_code': roleCode,
      if (isActive != null) 'is_active': isActive ? '1' : '0',
    };

    final response = await _client.get('/admin/users', queryParameters: query);
    return PaginatedResponse<AdminUser>.fromJson(response, AdminUser.fromJson);
  }

  Future<(String, AdminUser)> createUser({
    required int roleId,
    required int? departmentId,
    required String employeeCode,
    required String name,
    required String? email,
    required String? phone,
    required String password,
    required bool isActive,
  }) async {
    final response = await _client.post(
      '/admin/users',
      body: <String, dynamic>{
        'role_id': roleId,
        'department_id': departmentId,
        'employee_code': employeeCode,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'is_active': isActive,
      },
    );

    return (
      asString(response['message']) ?? 'Tao tai khoan thanh cong.',
      AdminUser.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, AdminUser)> updateUser(
    int userId, {
    int? roleId,
    int? departmentId,
    bool includeDepartment = false,
    String? employeeCode,
    String? name,
    String? email,
    String? phone,
    String? password,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (roleId != null) body['role_id'] = roleId;
    if (includeDepartment) body['department_id'] = departmentId;
    if (employeeCode != null) body['employee_code'] = employeeCode;
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (isActive != null) body['is_active'] = isActive;

    final response = await _client.put('/admin/users/$userId', body: body);

    return (
      asString(response['message']) ?? 'Cap nhat tai khoan thanh cong.',
      AdminUser.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<String> deleteUser(int userId) async {
    final response = await _client.delete('/admin/users/$userId');
    return asString(response['message']) ?? 'Xoa tai khoan thanh cong.';
  }
}
