import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return kIsWeb
        ? 'http://localhost:8000/api'
        : 'http://10.0.2.2:8000/api';
  }

  static String normalizeBaseUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }

    var normalized = trimmed;

    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }

    normalized = normalized.replaceAll(RegExp(r'/+$'), '');

    if (!normalized.endsWith('/api')) {
      normalized = '$normalized/api';
    }

    return normalized;
  }
}
