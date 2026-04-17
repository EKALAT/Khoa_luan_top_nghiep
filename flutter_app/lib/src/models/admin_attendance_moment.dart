import '../core/utils/json_utils.dart';

class AdminAttendanceMoment {
  const AdminAttendanceMoment({
    required this.id,
    required this.checkType,
    required this.checkTime,
    this.workLocationName,
  });

  final int id;
  final String checkType;
  final String checkTime;
  final String? workLocationName;

  factory AdminAttendanceMoment.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceMoment(
      id: asInt(json['id']) ?? 0,
      checkType: asString(json['check_type']) ?? '',
      checkTime: asString(json['check_time']) ?? '',
      workLocationName: asString(json['work_location_name']),
    );
  }
}
