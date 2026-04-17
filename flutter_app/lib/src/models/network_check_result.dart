import '../core/utils/json_utils.dart';

class NetworkCheckResult {
  const NetworkCheckResult({
    required this.message,
    this.reason,
    required this.workLocationId,
    required this.workLocationName,
    required this.requestIp,
    this.allowedNetwork,
    this.clientNetworkInfo,
    required this.isAllowed,
  });

  final String message;
  final String? reason;
  final int workLocationId;
  final String workLocationName;
  final String requestIp;
  final String? allowedNetwork;
  final String? clientNetworkInfo;
  final bool isAllowed;

  factory NetworkCheckResult.fromJson(Map<String, dynamic> json) {
    final data = asMap(json['data']);
    return NetworkCheckResult(
      message: asString(json['message']) ?? '',
      reason: asString(json['reason']),
      workLocationId: asInt(data['work_location_id']) ?? 0,
      workLocationName: asString(data['work_location_name']) ?? '',
      requestIp: asString(data['request_ip']) ?? '--',
      allowedNetwork: asString(data['allowed_network']),
      clientNetworkInfo: asString(data['client_network_info']),
      isAllowed: asBool(data['is_allowed']),
    );
  }
}
