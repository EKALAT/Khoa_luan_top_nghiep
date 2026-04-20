import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/work_location.dart';

class AdminWorkLocationRepository {
  const AdminWorkLocationRepository(this._client);

  final ApiClient _client;

  Future<List<WorkLocation>> fetchWorkLocations() async {
    final response = await _client.get('/admin/work-locations');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];

    return items
        .map(
          (item) =>
              WorkLocation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<(String, WorkLocation)> createWorkLocation({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required int radiusM,
    String? allowedNetwork,
    required bool isActive,
  }) async {
    final response = await _client.post(
      '/work-locations',
      body: <String, dynamic>{
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': radiusM,
        'allowed_network': allowedNetwork,
        'is_active': isActive,
      },
    );

    return (
      asString(response['message']) ?? 'Tao dia diem cong ty thanh cong.',
      WorkLocation.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, WorkLocation)> updateWorkLocation({
    required int workLocationId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radiusM,
    String? allowedNetwork,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (radiusM != null) body['radius_m'] = radiusM;
    if (allowedNetwork != null) body['allowed_network'] = allowedNetwork;
    if (isActive != null) body['is_active'] = isActive;

    final response = await _client.put(
      '/work-locations/$workLocationId',
      body: body,
    );

    return (
      asString(response['message']) ?? 'Cap nhat dia diem cong ty thanh cong.',
      WorkLocation.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<String> deleteWorkLocation(int workLocationId) async {
    final response = await _client.delete('/work-locations/$workLocationId');
    return asString(response['message']) ?? 'Xoa dia diem cong ty thanh cong.';
  }
}
