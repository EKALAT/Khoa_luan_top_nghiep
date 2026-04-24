import '../core/utils/json_utils.dart';
import 'admin_attendance_user.dart';
import 'paginated_response.dart';

class AdminAttendanceOverview {
  const AdminAttendanceOverview({
    required this.page,
    required this.summary,
  });

  final PaginatedResponse<AdminAttendanceUser> page;
  final AdminAttendanceSummary summary;

  factory AdminAttendanceOverview.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceOverview(
      page: PaginatedResponse<AdminAttendanceUser>.fromJson(
        json,
        AdminAttendanceUser.fromJson,
      ),
      summary: AdminAttendanceSummary.fromJson(asMap(json['summary'])),
    );
  }
}

class AdminAttendanceSummary {
  const AdminAttendanceSummary({
    required this.date,
    required this.expectedValidRecords,
    required this.totalUsers,
    required this.checkedInCount,
    required this.notCheckedInCount,
    required this.partialCount,
    required this.completedCount,
    required this.recentActivities,
  });

  final String date;
  final int expectedValidRecords;
  final int totalUsers;
  final int checkedInCount;
  final int notCheckedInCount;
  final int partialCount;
  final int completedCount;
  final List<AdminAttendanceRecentActivity> recentActivities;

  factory AdminAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final rawRecentActivities =
        json['recent_activities'] as List<dynamic>? ?? const [];

    return AdminAttendanceSummary(
      date: asString(json['date']) ?? '',
      expectedValidRecords: asInt(json['expected_valid_records']) ?? 4,
      totalUsers: asInt(json['total_users']) ?? 0,
      checkedInCount: asInt(json['checked_in_count']) ?? 0,
      notCheckedInCount: asInt(json['not_checked_in_count']) ?? 0,
      partialCount: asInt(json['partial_count']) ?? 0,
      completedCount: asInt(json['completed_count']) ?? 0,
      recentActivities: rawRecentActivities
          .map(
            (item) => AdminAttendanceRecentActivity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class AdminAttendanceRecentActivity {
  const AdminAttendanceRecentActivity({
    required this.id,
    this.employeeCode,
    this.name,
    this.department,
    this.avatarPath,
    this.avatarUrl,
    this.checkType,
    this.checkTime,
    this.workLocationName,
  });

  final int id;
  final String? employeeCode;
  final String? name;
  final String? department;
  final String? avatarPath;
  final String? avatarUrl;
  final String? checkType;
  final String? checkTime;
  final String? workLocationName;

  factory AdminAttendanceRecentActivity.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecentActivity(
      id: asInt(json['id']) ?? 0,
      employeeCode: asString(json['employee_code']),
      name: asString(json['name']),
      department: asString(json['department']),
      avatarPath: asString(json['avatar_path']),
      avatarUrl: asString(json['avatar_url']),
      checkType: asString(json['check_type']),
      checkTime: asString(json['check_time']),
      workLocationName: asString(json['work_location_name']),
    );
  }
}
