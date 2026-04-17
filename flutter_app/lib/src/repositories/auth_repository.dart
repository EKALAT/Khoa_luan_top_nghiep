import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/app_user.dart';
import '../models/login_result.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final ApiClient _client;

  Future<LoginResult> login({
    required String employeeCode,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      authenticated: false,
      body: <String, dynamic>{
        'employee_code': employeeCode,
        'password': password,
      },
    );

    return LoginResult(
      message: asString(response['message']) ?? '',
      token: asString(response['token']) ?? '',
      tokenType: asString(response['token_type']) ?? 'Bearer',
      user: AppUser.fromJson(
        Map<String, dynamic>.from(response['user'] as Map),
      ),
    );
  }

  Future<AppUser> me() async {
    final response = await _client.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(response['user'] as Map));
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
}
