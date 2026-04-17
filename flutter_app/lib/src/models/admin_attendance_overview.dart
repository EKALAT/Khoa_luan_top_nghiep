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
  });

  final String date;
  final int expectedValidRecords;
  final int totalUsers;
  final int checkedInCount;
  final int notCheckedInCount;
  final int partialCount;
  final int completedCount;

  factory AdminAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceSummary(
      date: asString(json['date']) ?? '',
      expectedValidRecords: asInt(json['expected_valid_records']) ?? 4,
      totalUsers: asInt(json['total_users']) ?? 0,
      checkedInCount: asInt(json['checked_in_count']) ?? 0,
      notCheckedInCount: asInt(json['not_checked_in_count']) ?? 0,
      partialCount: asInt(json['partial_count']) ?? 0,
      completedCount: asInt(json['completed_count']) ?? 0,
    );
  }
}
