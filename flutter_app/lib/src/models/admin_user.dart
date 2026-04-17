import '../core/utils/json_utils.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.avatarUrl,
    this.roleId,
    this.role,
    this.roleCode,
    this.departmentId,
    this.department,
    this.departmentCode,
    required this.isActive,
    this.lastLoginAt,
  });

  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String? avatarUrl;
  final int? roleId;
  final String? role;
  final String? roleCode;
  final int? departmentId;
  final String? department;
  final String? departmentCode;
  final bool isActive;
  final DateTime? lastLoginAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: asInt(json['id']) ?? 0,
      employeeCode: asString(json['employee_code']) ?? '',
      name: asString(json['name']) ?? '',
      email: asString(json['email']),
      phone: asString(json['phone']),
      avatarPath: asString(json['avatar_path']),
      avatarUrl: asString(json['avatar_url']),
      roleId: asInt(json['role_id']),
      role: asString(json['role']),
      roleCode: asString(json['role_code']),
      departmentId: asInt(json['department_id']),
      department: asString(json['department']),
      departmentCode: asString(json['department_code']),
      isActive: asBool(json['is_active']),
      lastLoginAt: parseDateTime(json['last_login_at']),
    );
  }
}
