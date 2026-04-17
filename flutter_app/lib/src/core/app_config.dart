class AppConfig {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

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
