import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../app_config.dart';

class SessionStorage {
  static const _tokenKey = 'session.token';
  static const _userKey = 'session.user';
  static const _baseUrlKey = 'session.base_url';

  Future<SessionSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final userRaw = preferences.getString(_userKey);

    return SessionSnapshot(
      token: preferences.getString(_tokenKey),
      baseUrl: preferences.getString(_baseUrlKey) ?? AppConfig.defaultBaseUrl,
      user:
          userRaw == null
              ? null
              : AppUser.fromJson(
                Map<String, dynamic>.from(jsonDecode(userRaw) as Map),
              ),
    );
  }

  Future<void> saveSession({
    required String token,
    required AppUser user,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseUrlKey, baseUrl);
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userKey);
  }
}

class SessionSnapshot {
  const SessionSnapshot({
    required this.token,
    required this.baseUrl,
    required this.user,
  });

  final String? token;
  final String baseUrl;
  final AppUser? user;
}
