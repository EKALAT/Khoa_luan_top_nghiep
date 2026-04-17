import '../core/utils/json_utils.dart';

class RoleOption {
  const RoleOption({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  final int id;
  final String name;
  final String code;
  final String? description;

  factory RoleOption.fromJson(Map<String, dynamic> json) {
    return RoleOption(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      code: asString(json['code']) ?? '',
      description: asString(json['description']),
    );
  }
}
