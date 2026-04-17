import '../core/utils/json_utils.dart';

class AdminPayrollUser {
  const AdminPayrollUser({
    required this.id,
    required this.employeeCode,
    required this.name,
    this.email,
    this.phone,
    this.avatarPath,
    this.avatarUrl,
    this.department,
    this.departmentCode,
    required this.monthlySalary,
    required this.totalWorkUnits,
    required this.paidWorkUnits,
    required this.unitSalary,
    required this.salaryAmount,
  });

  final int id;
  final String employeeCode;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final String? avatarUrl;
  final String? department;
  final String? departmentCode;
  final double monthlySalary;
  final double totalWorkUnits;
  final double paidWorkUnits;
  final double unitSalary;
  final double salaryAmount;

  factory AdminPayrollUser.fromJson(Map<String, dynamic> json) {
    return AdminPayrollUser(
      id: asInt(json['id']) ?? 0,
      employeeCode: asString(json['employee_code']) ?? '',
      name: asString(json['name']) ?? '',
      email: asString(json['email']),
      phone: asString(json['phone']),
      avatarPath: asString(json['avatar_path']),
      avatarUrl: asString(json['avatar_url']),
      department: asString(json['department']),
      departmentCode: asString(json['department_code']),
      monthlySalary: asDouble(json['monthly_salary']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      paidWorkUnits: asDouble(json['paid_work_units']) ?? 0,
      unitSalary: asDouble(json['unit_salary']) ?? 0,
      salaryAmount: asDouble(json['salary_amount']) ?? 0,
    );
  }
}
