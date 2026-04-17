import '../core/utils/json_utils.dart';
import 'admin_monthly_attendance_day.dart';

class AdminMonthlyAttendanceUser {
  const AdminMonthlyAttendanceUser({
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
    this.departmentCode,
    this.lastLoginAt,
    required this.trackedDayCount,
    required this.recordedDayCount,
    required this.fullDayCount,
    required this.halfDayCount,
    required this.incompleteDayCount,
    required this.daysWithoutRecordCount,
    required this.totalWorkUnits,
    this.latestAttendanceDate,
    this.latestDayStatus,
    required this.dailyBreakdown,
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
  final String? departmentCode;
  final DateTime? lastLoginAt;
  final int trackedDayCount;
  final int recordedDayCount;
  final int fullDayCount;
  final int halfDayCount;
  final int incompleteDayCount;
  final int daysWithoutRecordCount;
  final double totalWorkUnits;
  final String? latestAttendanceDate;
  final String? latestDayStatus;
  final List<AdminMonthlyAttendanceDay> dailyBreakdown;

  factory AdminMonthlyAttendanceUser.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['daily_breakdown'] as List<dynamic>? ?? const [];

    return AdminMonthlyAttendanceUser(
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
      departmentCode: asString(json['department_code']),
      lastLoginAt: parseDateTime(json['last_login_at']),
      trackedDayCount: asInt(json['tracked_day_count']) ?? 0,
      recordedDayCount: asInt(json['recorded_day_count']) ?? 0,
      fullDayCount: asInt(json['full_day_count']) ?? 0,
      halfDayCount: asInt(json['half_day_count']) ?? 0,
      incompleteDayCount: asInt(json['incomplete_day_count']) ?? 0,
      daysWithoutRecordCount: asInt(json['days_without_record_count']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      latestAttendanceDate: asString(json['latest_attendance_date']),
      latestDayStatus: asString(json['latest_day_status']),
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
