import '../core/network/api_client.dart';
import '../models/department_option.dart';
import '../models/role_option.dart';
import '../models/shift_rule.dart';
import '../models/work_location.dart';

class MetaRepository {
  const MetaRepository(this._client);

  final ApiClient _client;

  Future<List<WorkLocation>> fetchWorkLocations() async {
    final response = await _client.get('/work-locations');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map(
          (item) =>
              WorkLocation.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<ShiftRule>> fetchShiftRules() async {
    final response = await _client.get('/shift-rules');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map(
          (item) => ShiftRule.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<RoleOption>> fetchRoles() async {
    final response = await _client.get('/admin/roles');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map(
          (item) => RoleOption.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<DepartmentOption>> fetchDepartments() async {
    final response = await _client.get('/admin/departments');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map(
          (item) => DepartmentOption.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}
