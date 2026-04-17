import '../core/utils/json_utils.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.avatarUrl,
  });

  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: asInt(json['id']) ?? 0,
      employeeCode: asString(json['employee_code']) ?? '',
      name: asString(json['name']) ?? '',
      email: asString(json['email']),
      phone: asString(json['phone']),
      avatarPath: asString(json['avatar_path']),
      avatarUrl: asString(json['avatar_url']),
    );
  }
}
