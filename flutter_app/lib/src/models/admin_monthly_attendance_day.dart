import '../core/utils/json_utils.dart';
import 'admin_attendance_moment.dart';

class AdminMonthlyAttendanceDay {
  const AdminMonthlyAttendanceDay({
    required this.date,
    required this.validRecordCount,
    required this.workUnits,
    required this.status,
    required this.moments,
  });

  final String date;
  final int validRecordCount;
  final double workUnits;
  final String status;
  final List<AdminAttendanceMoment> moments;

  factory AdminMonthlyAttendanceDay.fromJson(Map<String, dynamic> json) {
    final rawMoments = json['moments'] as List<dynamic>? ?? const [];

    return AdminMonthlyAttendanceDay(
      date: asString(json['date']) ?? '',
      validRecordCount: asInt(json['valid_record_count']) ?? 0,
      workUnits: asDouble(json['work_units']) ?? 0,
      status: asString(json['status']) ?? 'not_recorded',
      moments: rawMoments
          .map(
            (item) => AdminAttendanceMoment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
