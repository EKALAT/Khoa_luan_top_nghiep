import '../core/utils/json_utils.dart';

class WorkLocation {
  const WorkLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
    this.allowedNetwork,
    required this.isActive,
  });

  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusM;
  final String? allowedNetwork;
  final bool isActive;

  factory WorkLocation.fromJson(Map<String, dynamic> json) {
    return WorkLocation(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      address: asString(json['address']),
      latitude: asDouble(json['latitude']) ?? 0,
      longitude: asDouble(json['longitude']) ?? 0,
      radiusM: asInt(json['radius_m']) ?? 0,
      allowedNetwork: asString(json['allowed_network']),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
