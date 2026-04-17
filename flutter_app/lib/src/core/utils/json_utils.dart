DateTime? parseDateTime(dynamic value) {
  final stringValue = asString(value);
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }

  return DateTime.tryParse(stringValue);
}

String? asString(dynamic value) {
  if (value == null) {
    return null;
  }
  final converted = value.toString();
  return converted.isEmpty ? null : converted;
}

int? asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final stringValue = asString(value);
  return stringValue == null ? null : int.tryParse(stringValue);
}

double? asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final stringValue = asString(value);
  return stringValue == null ? null : double.tryParse(stringValue);
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }

  final normalized = asString(value)?.toLowerCase();
  return switch (normalized) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}
