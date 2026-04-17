import '../core/utils/json_utils.dart';
import 'attendance_record.dart';

class AttendanceActionResult {
  const AttendanceActionResult({
    required this.message,
    this.reason,
    this.record,
    this.distanceM,
    this.data = const <String, dynamic>{},
  });

  final String message;
  final String? reason;
  final AttendanceRecord? record;
  final double? distanceM;
  final Map<String, dynamic> data;

  factory AttendanceActionResult.fromJson(Map<String, dynamic> json) {
    final recordJson = asMap(json['data']);
    return AttendanceActionResult(
      message: asString(json['message']) ?? '',
      reason: asString(json['reason']),
      record: recordJson.isEmpty ? null : AttendanceRecord.fromJson(recordJson),
      distanceM: asDouble(json['distance_m']),
      data: recordJson,
    );
  }
}
