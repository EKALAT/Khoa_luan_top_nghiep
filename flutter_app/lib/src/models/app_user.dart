import '../core/utils/json_utils.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.avatarUrl,
    this.role,
    this.roleCode,
    this.department,
    this.lastLoginAt,
  });

  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String? avatarUrl;
  final String? role;
  final String? roleCode;
  final String? department;
  final DateTime? lastLoginAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: asInt(json['id']) ?? 0,
      employeeCode: asString(json['employee_code']) ?? '',
      name: asString(json['name']) ?? '',
      email: asString(json['email']),
      phone: asString(json['phone']),
      avatarPath: asString(json['avatar_path']),
      avatarUrl: asString(json['avatar_url']),
      role: asString(json['role']),
      roleCode: asString(json['role_code']),
      department: asString(json['department']),
      lastLoginAt: parseDateTime(json['last_login_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_path': avatarPath,
      'avatar_url': avatarUrl,
      'role': role,
      'role_code': roleCode,
      'department': department,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    int? id,
    String? employeeCode,
    String? name,
    String? email,
    String? phone,
    String? avatarPath,
    String? avatarUrl,
    String? role,
    String? roleCode,
    String? department,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      roleCode: roleCode ?? this.roleCode,
      department: department ?? this.department,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
