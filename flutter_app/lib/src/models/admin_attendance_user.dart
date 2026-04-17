import '../core/utils/json_utils.dart';
import 'admin_attendance_moment.dart';

class AdminAttendanceUser {
  const AdminAttendanceUser({
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
    required this.attendanceStatus,
    required this.validRecordCount,
    this.latestCheckTime,
    this.latestCheckType,
    required this.todayRecords,
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
  final String attendanceStatus;
  final int validRecordCount;
  final String? latestCheckTime;
  final String? latestCheckType;
  final List<AdminAttendanceMoment> todayRecords;

  factory AdminAttendanceUser.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['today_records'] as List<dynamic>? ?? const [];

    return AdminAttendanceUser(
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
      attendanceStatus: asString(json['attendance_status']) ?? 'not_checked_in',
      validRecordCount: asInt(json['valid_record_count']) ?? 0,
      latestCheckTime: asString(json['latest_check_time']),
      latestCheckType: asString(json['latest_check_type']),
      todayRecords: rawRecords
          .map(
            (item) => AdminAttendanceMoment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
