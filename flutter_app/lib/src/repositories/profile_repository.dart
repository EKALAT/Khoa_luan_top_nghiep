import '../core/network/api_client.dart';
import '../core/utils/json_utils.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final ApiClient _client;

  Future<UserProfile> fetchProfile() async {
    final response = await _client.get('/profile');
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<(String, UserProfile)> updateProfile({
    required String name,
    required String? email,
    required String? phone,
  }) async {
    final response = await _client.put(
      '/profile',
      body: <String, dynamic>{'name': name, 'email': email, 'phone': phone},
    );

    return (
      asString(response['message']) ?? 'Cap nhat ho so thanh cong.',
      UserProfile.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }

  Future<(String, UserProfile)> uploadAvatar({
    required String filePath,
  }) async {
    final filename = filePath.split(RegExp(r'[\\/]')).last;
    final response = await _client.postMultipart(
      '/profile/avatar',
      files: [
        MultipartFilePayload(
          field: 'avatar',
          path: filePath,
          filename: filename,
        ),
      ],
    );

    return (
      asString(response['message']) ?? 'Cap nhat anh dai dien thanh cong.',
      UserProfile.fromJson(Map<String, dynamic>.from(response['data'] as Map)),
    );
  }
}
