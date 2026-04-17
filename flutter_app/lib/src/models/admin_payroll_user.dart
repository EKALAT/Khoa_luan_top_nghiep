import '../core/utils/json_utils.dart';
import 'admin_monthly_attendance_day.dart';

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
    this.lastLoginAt,
    required this.monthlySalary,
    required this.standardWorkDays,
    required this.unitSalary,
    required this.totalWorkUnits,
    required this.payableWorkUnits,
    required this.netSalary,
    required this.hasSalaryConfigured,
    required this.dailyBreakdown,
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
  final DateTime? lastLoginAt;
  final double monthlySalary;
  final double standardWorkDays;
  final double unitSalary;
  final double totalWorkUnits;
  final double payableWorkUnits;
  final double netSalary;
  final bool hasSalaryConfigured;
  final List<AdminMonthlyAttendanceDay> dailyBreakdown;

  factory AdminPayrollUser.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['daily_breakdown'] as List<dynamic>? ?? const [];

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
      lastLoginAt: parseDateTime(json['last_login_at']),
      monthlySalary: asDouble(json['monthly_salary']) ?? 0,
      standardWorkDays: asDouble(json['standard_work_days']) ?? 25,
      unitSalary: asDouble(json['unit_salary']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      payableWorkUnits: asDouble(json['payable_work_units']) ?? 0,
      netSalary: asDouble(json['net_salary']) ?? 0,
      hasSalaryConfigured: asBool(json['has_salary_configured']),
      dailyBreakdown: rawBreakdown
          .map(
            (item) => AdminMonthlyAttendanceDay.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
