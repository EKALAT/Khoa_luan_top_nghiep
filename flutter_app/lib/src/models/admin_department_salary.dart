import '../core/utils/json_utils.dart';

class AdminDepartmentSalary {
  const AdminDepartmentSalary({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.monthlySalary,
    required this.isActive,
    required this.userCount,
  });

  final int id;
  final String name;
  final String code;
  final String? description;
  final double monthlySalary;
  final bool isActive;
  final int userCount;

  factory AdminDepartmentSalary.fromJson(Map<String, dynamic> json) {
    return AdminDepartmentSalary(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      code: asString(json['code']) ?? '',
      description: asString(json['description']),
      monthlySalary: asDouble(json['monthly_salary']) ?? 0,
      isActive: asBool(json['is_active'], fallback: true),
      userCount: asInt(json['user_count']) ?? 0,
    );
  }
}
