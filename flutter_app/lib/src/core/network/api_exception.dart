import 'dart:convert';

import '../utils/json_utils.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.reason,
    this.errors = const {},
    this.payload = const {},
  });

  final String message;
  final int? statusCode;
  final String? reason;
  final Map<String, List<String>> errors;
  final Map<String, dynamic> payload;

  factory ApiException.fromResponse(int statusCode, String body) {
    final json = _tryDecode(body);
    final errors = _parseErrors(json['errors']);

    return ApiException(
      message: _extractMessage(json, statusCode),
      statusCode: statusCode,
      reason: asString(json['reason']),
      errors: errors,
      payload: json,
    );
  }

  factory ApiException.timeout([Duration? duration]) {
    final seconds = duration?.inSeconds;
    final detail =
        seconds == null
            ? 'Khong nhan duoc phan hoi tu may chu.'
            : 'Khong nhan duoc phan hoi tu may chu sau $seconds giay.';

    return ApiException(
      message:
          'Ket noi may chu bi timeout. Vui long kiem tra backend va thu lai.',
      reason: detail,
    );
  }

  factory ApiException.network({String? details}) {
    return ApiException(
      message:
          'Khong the ket noi toi may chu. Hay kiem tra backend dang chay va base URL trong ung dung.',
      reason: details,
    );
  }

  factory ApiException.invalidResponse() {
    return ApiException(
      message:
          'May chu tra ve du lieu khong hop le. Vui long kiem tra API backend.',
      reason: 'invalid_response',
    );
  }

  static Map<String, dynamic> _tryDecode(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  static String _extractMessage(Map<String, dynamic> json, int statusCode) {
    final directMessage = asString(json['message']);
    if (directMessage != null && directMessage.isNotEmpty) {
      return directMessage;
    }

    final errors = _parseErrors(json['errors']);
    if (errors.isNotEmpty) {
      return errors.values.first.first;
    }

    return switch (statusCode) {
      401 => 'Phien dang nhap khong hop le hoac da het han.',
      403 => 'Tai khoan khong co quyen thuc hien thao tac nay.',
      422 => 'Du lieu gui len chua hop le.',
      _ => 'Co loi xay ra khi giao tiep voi may chu.',
    };
  }

  static Map<String, List<String>> _parseErrors(dynamic value) {
    if (value is! Map) {
      return const <String, List<String>>{};
    }

    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      final messages = entry.value;
      if (messages is List) {
        result[entry.key.toString()] = messages
            .map((item) => item.toString())
            .toList(growable: false);
      }
    }
    return result;
  }

  @override
  String toString() => message;
}
