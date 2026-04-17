import '../core/utils/json_utils.dart';

class ShiftRule {
  const ShiftRule({
    required this.id,
    required this.name,
    required this.morningCheckInStart,
    required this.morningCheckInEnd,
    required this.morningCheckOutStart,
    required this.morningCheckOutEnd,
    required this.afternoonCheckInStart,
    required this.afternoonCheckInEnd,
    required this.afternoonCheckOutStart,
    required this.afternoonCheckOutEnd,
    required this.isActive,
  });

  final int id;
  final String name;
  final String morningCheckInStart;
  final String morningCheckInEnd;
  final String morningCheckOutStart;
  final String morningCheckOutEnd;
  final String afternoonCheckInStart;
  final String afternoonCheckInEnd;
  final String afternoonCheckOutStart;
  final String afternoonCheckOutEnd;
  final bool isActive;

  factory ShiftRule.fromJson(Map<String, dynamic> json) {
    return ShiftRule(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      morningCheckInStart: asString(json['morning_check_in_start']) ?? '--',
      morningCheckInEnd: asString(json['morning_check_in_end']) ?? '--',
      morningCheckOutStart: asString(json['morning_check_out_start']) ?? '--',
      morningCheckOutEnd: asString(json['morning_check_out_end']) ?? '--',
      afternoonCheckInStart: asString(json['afternoon_check_in_start']) ?? '--',
      afternoonCheckInEnd: asString(json['afternoon_check_in_end']) ?? '--',
      afternoonCheckOutStart:
          asString(json['afternoon_check_out_start']) ?? '--',
      afternoonCheckOutEnd: asString(json['afternoon_check_out_end']) ?? '--',
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
