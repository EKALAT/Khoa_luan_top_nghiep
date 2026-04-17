import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/src/core/app_config.dart';

void main() {
  test('normalizeBaseUrl appends api segment when missing', () {
    expect(
      AppConfig.normalizeBaseUrl('http://localhost:8000'),
      'http://localhost:8000/api',
    );
  });

  test('normalizeBaseUrl keeps api segment and trims trailing slash', () {
    expect(
      AppConfig.normalizeBaseUrl('https://demo.ngrok-free.app/api/'),
      'https://demo.ngrok-free.app/api',
    );
  });
}
