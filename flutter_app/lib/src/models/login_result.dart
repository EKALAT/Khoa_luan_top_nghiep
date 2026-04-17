import 'app_user.dart';

class LoginResult {
  const LoginResult({
    required this.message,
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String message;
  final String token;
  final String tokenType;
  final AppUser user;
}
