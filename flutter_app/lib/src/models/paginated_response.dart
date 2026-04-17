import '../core/utils/json_utils.dart';

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = json['data'] as List<dynamic>? ?? const <dynamic>[];
    return PaginatedResponse<T>(
      data: rawItems
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      currentPage: asInt(json['current_page']) ?? 1,
      lastPage: asInt(json['last_page']) ?? 1,
      total: asInt(json['total']) ?? rawItems.length,
      perPage: asInt(json['per_page']) ?? rawItems.length,
    );
  }
}
