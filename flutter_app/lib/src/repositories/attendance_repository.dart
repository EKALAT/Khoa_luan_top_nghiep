import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/attendance_action_result.dart';
import '../models/attendance_log.dart';
import '../models/attendance_record.dart';
import '../models/network_check_result.dart';
import '../models/paginated_response.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);

  final ApiClient _client;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<PaginatedResponse<AttendanceRecord>> fetchAttendance({
    DateTime? date,
    String? status,
    String? checkType,
    int page = 1,
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      if (date != null) 'date': _dateFormat.format(date),
      if (status != null && status.isNotEmpty) 'status': status,
      if (checkType != null && checkType.isNotEmpty) 'check_type': checkType,
    };

    final response = await _client.get(
      '/attendance',
      queryParameters: queryParameters,
    );

    return PaginatedResponse<AttendanceRecord>.fromJson(
      response,
      AttendanceRecord.fromJson,
    );
  }

  Future<PaginatedResponse<AttendanceLog>> fetchLogs({int page = 1}) async {
    final response = await _client.get(
      '/attendance/logs',
      queryParameters: <String, String>{'page': '$page'},
    );

    return PaginatedResponse<AttendanceLog>.fromJson(
      response,
      AttendanceLog.fromJson,
    );
  }

  Future<NetworkCheckResult> networkCheck({
    required int workLocationId,
    String? networkInfo,
  }) async {
    final response = await _client.get(
      '/attendance/network-check',
      queryParameters: <String, String>{
        'work_location_id': '$workLocationId',
        if (networkInfo != null && networkInfo.isNotEmpty)
          'network_info': networkInfo,
      },
    );

    return NetworkCheckResult.fromJson(response);
  }

  Future<AttendanceActionResult> submitAttendance({
    required bool isCheckIn,
    required int workLocationId,
    required double latitude,
    required double longitude,
    required double accuracyM,
    String? networkInfo,
    String? deviceInfo,
  }) async {
    final response = await _client.post(
      isCheckIn ? '/attendance/check-in' : '/attendance/check-out',
      body: <String, dynamic>{
        'work_location_id': workLocationId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_m': accuracyM,
        'network_info': networkInfo,
        'device_info': deviceInfo,
      },
    );

    return AttendanceActionResult.fromJson(response);
  }
}
