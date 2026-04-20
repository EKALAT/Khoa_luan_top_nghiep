import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/shift_rule.dart';

class AdminShiftRuleRepository {
  const AdminShiftRuleRepository(this._client);

  final ApiClient _client;

  Future<List<ShiftRule>> fetchShiftRules() async {
    final response = await _client.get('/admin/shift-rules');
    final items = response['data'] as List<dynamic>? ?? const <dynamic>[];

    return items
        .map(
          (item) => ShiftRule.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<(String, ShiftRule)> createShiftRule({
    required String name,
    required String morningCheckInStart,
    required String morningCheckInEnd,
    required String morningCheckOutStart,
    required String morningCheckOutEnd,
    required String afternoonCheckInStart,
    required String afternoonCheckInEnd,
    required String afternoonCheckOutStart,
    required String afternoonCheckOutEnd,
    required bool isActive,
  }) async {
    final response = await _client.post(
      '/shift-rules',
      body: <String, dynamic>{
        'name': name,
        'morning_check_in_start': morningCheckInStart,
        'morning_check_in_end': morningCheckInEnd,
        'morning_check_out_start': morningCheckOutStart,
        'morning_check_out_end': morningCheckOutEnd,
        'afternoon_check_in_start': afternoonCheckInStart,
        'afternoon_check_in_end': afternoonCheckInEnd,
        'afternoon_check_out_start': afternoonCheckOutStart,
        'afternoon_check_out_end': afternoonCheckOutEnd,
        'is_active': isActive,
      },
    );

    return (
      asString(response['message']) ?? 'Tao khung gio thanh cong.',
      ShiftRule.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, ShiftRule)> updateShiftRule({
    required int shiftRuleId,
    String? name,
    String? morningCheckInStart,
    String? morningCheckInEnd,
    String? morningCheckOutStart,
    String? morningCheckOutEnd,
    String? afternoonCheckInStart,
    String? afternoonCheckInEnd,
    String? afternoonCheckOutStart,
    String? afternoonCheckOutEnd,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (morningCheckInStart != null) {
      body['morning_check_in_start'] = morningCheckInStart;
    }
    if (morningCheckInEnd != null) {
      body['morning_check_in_end'] = morningCheckInEnd;
    }
    if (morningCheckOutStart != null) {
      body['morning_check_out_start'] = morningCheckOutStart;
    }
    if (morningCheckOutEnd != null) {
      body['morning_check_out_end'] = morningCheckOutEnd;
    }
    if (afternoonCheckInStart != null) {
      body['afternoon_check_in_start'] = afternoonCheckInStart;
    }
    if (afternoonCheckInEnd != null) {
      body['afternoon_check_in_end'] = afternoonCheckInEnd;
    }
    if (afternoonCheckOutStart != null) {
      body['afternoon_check_out_start'] = afternoonCheckOutStart;
    }
    if (afternoonCheckOutEnd != null) {
      body['afternoon_check_out_end'] = afternoonCheckOutEnd;
    }
    if (isActive != null) body['is_active'] = isActive;

    final response = await _client.put('/shift-rules/$shiftRuleId', body: body);

    return (
      asString(response['message']) ?? 'Cap nhat khung gio thanh cong.',
      ShiftRule.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<String> deleteShiftRule(int shiftRuleId) async {
    final response = await _client.delete('/shift-rules/$shiftRuleId');
    return asString(response['message']) ?? 'Xoa khung gio thanh cong.';
  }
}
