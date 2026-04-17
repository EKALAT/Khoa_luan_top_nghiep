import '../core/utils/json_utils.dart';
import 'work_location.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.workLocationId,
    required this.checkType,
    required this.status,
    this.checkDate,
    this.checkTime,
    this.distanceM,
    this.accuracyM,
    this.reason,
    this.workLocation,
  });

  final int id;
  final int userId;
  final int workLocationId;
  final String checkType;
  final String status;
  final DateTime? checkDate;
  final String? checkTime;
  final double? distanceM;
  final double? accuracyM;
  final String? reason;
  final WorkLocation? workLocation;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final workLocationJson = asMap(json['work_location']);

    return AttendanceRecord(
      id: asInt(json['id']) ?? 0,
      userId: asInt(json['user_id']) ?? 0,
      workLocationId: asInt(json['work_location_id']) ?? 0,
      checkType: asString(json['check_type']) ?? '',
      status: asString(json['status']) ?? '',
      checkDate: parseDateTime(json['check_date']),
      checkTime: asString(json['check_time']),
      distanceM: asDouble(json['distance_m']),
      accuracyM: asDouble(json['accuracy_m']),
      reason: asString(json['reason']),
      workLocation:
          workLocationJson.isEmpty
              ? null
              : WorkLocation.fromJson(workLocationJson),
    );
  }
}
