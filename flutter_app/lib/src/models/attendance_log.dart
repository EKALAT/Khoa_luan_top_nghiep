import '../core/utils/json_utils.dart';
import 'attendance_record.dart';

class AttendanceLog {
  const AttendanceLog({
    required this.id,
    required this.userId,
    this.attendanceRecordId,
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.capturedAt,
    this.deviceInfo,
    this.networkInfo,
    required this.result,
    this.reason,
    this.attendanceRecord,
  });

  final int id;
  final int userId;
  final int? attendanceRecordId;
  final double lat;
  final double lng;
  final double? accuracyM;
  final DateTime? capturedAt;
  final String? deviceInfo;
  final String? networkInfo;
  final String result;
  final String? reason;
  final AttendanceRecord? attendanceRecord;

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    final recordJson = asMap(json['attendance_record']);

    return AttendanceLog(
      id: asInt(json['id']) ?? 0,
      userId: asInt(json['user_id']) ?? 0,
      attendanceRecordId: asInt(json['attendance_record_id']),
      lat: asDouble(json['lat']) ?? 0,
      lng: asDouble(json['lng']) ?? 0,
      accuracyM: asDouble(json['accuracy_m']),
      capturedAt: parseDateTime(json['captured_at']),
      deviceInfo: asString(json['device_info']),
      networkInfo: asString(json['network_info']),
      result: asString(json['result']) ?? '',
      reason: asString(json['reason']),
      attendanceRecord:
          recordJson.isEmpty ? null : AttendanceRecord.fromJson(recordJson),
    );
  }
}
