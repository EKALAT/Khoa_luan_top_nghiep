import '../core/utils/json_utils.dart';
import 'admin_monthly_attendance_user.dart';
import 'paginated_response.dart';

class AdminMonthlyAttendanceOverview {
  const AdminMonthlyAttendanceOverview({
    required this.page,
    required this.summary,
  });

  final PaginatedResponse<AdminMonthlyAttendanceUser> page;
  final AdminMonthlyAttendanceSummary summary;

  factory AdminMonthlyAttendanceOverview.fromJson(Map<String, dynamic> json) {
    return AdminMonthlyAttendanceOverview(
      page: PaginatedResponse<AdminMonthlyAttendanceUser>.fromJson(
        json,
        AdminMonthlyAttendanceUser.fromJson,
      ),
      summary: AdminMonthlyAttendanceSummary.fromJson(asMap(json['summary'])),
    );
  }
}

class AdminMonthlyAttendanceSummary {
  const AdminMonthlyAttendanceSummary({
    required this.month,
    required this.monthLabel,
    required this.trackedDayCount,
    this.rangeEnd,
    required this.totalUsers,
    required this.employeeWithWorkCount,
    required this.employeeWithoutWorkCount,
    required this.totalWorkUnits,
    required this.fullDayTotal,
    required this.halfDayTotal,
    required this.incompleteDayTotal,
    required this.daysWithoutRecordTotal,
  });

  final String month;
  final String monthLabel;
  final int trackedDayCount;
  final String? rangeEnd;
  final int totalUsers;
  final int employeeWithWorkCount;
  final int employeeWithoutWorkCount;
  final double totalWorkUnits;
  final int fullDayTotal;
  final int halfDayTotal;
  final int incompleteDayTotal;
  final int daysWithoutRecordTotal;

  factory AdminMonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AdminMonthlyAttendanceSummary(
      month: asString(json['month']) ?? '',
      monthLabel: asString(json['month_label']) ?? '',
      trackedDayCount: asInt(json['tracked_day_count']) ?? 0,
      rangeEnd: asString(json['range_end']),
      totalUsers: asInt(json['total_users']) ?? 0,
      employeeWithWorkCount: asInt(json['employee_with_work_count']) ?? 0,
      employeeWithoutWorkCount: asInt(json['employee_without_work_count']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      fullDayTotal: asInt(json['full_day_total']) ?? 0,
      halfDayTotal: asInt(json['half_day_total']) ?? 0,
      incompleteDayTotal: asInt(json['incomplete_day_total']) ?? 0,
      daysWithoutRecordTotal: asInt(json['days_without_record_total']) ?? 0,
    );
  }
}
