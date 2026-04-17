import 'package:flutter/foundation.dart';

import 'core/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/api_exception.dart';
import 'core/storage/session_storage.dart';
import 'models/app_user.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/admin_attendance_repository.dart';
import 'repositories/admin_department_repository.dart';
import 'repositories/admin_payroll_repository.dart';
import 'repositories/admin_user_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/meta_repository.dart';
import 'repositories/profile_repository.dart';

enum AppBootstrapState { loading, unauthenticated, authenticated }

class AppSession extends ChangeNotifier {
  static const _minimumStartupDuration = Duration(seconds: 2);

  AppSession({SessionStorage? storage})
    : _storage = storage ?? SessionStorage(),
      _baseUrl = AppConfig.defaultBaseUrl {
    _apiClient = ApiClient(
      baseUrlReader: () => _baseUrl,
      tokenReader: () => _token,
    );
    authRepository = AuthRepository(_apiClient);
    attendanceRepository = AttendanceRepository(_apiClient);
    adminAttendanceRepository = AdminAttendanceRepository(_apiClient);
    adminDepartmentRepository = AdminDepartmentRepository(_apiClient);
    adminPayrollRepository = AdminPayrollRepository(_apiClient);
    adminUserRepository = AdminUserRepository(_apiClient);
    metaRepository = MetaRepository(_apiClient);
    profileRepository = ProfileRepository(_apiClient);
  }

  final SessionStorage _storage;
  late final ApiClient _apiClient;

  late final AuthRepository authRepository;
  late final AttendanceRepository attendanceRepository;
  late final AdminAttendanceRepository adminAttendanceRepository;
  late final AdminDepartmentRepository adminDepartmentRepository;
  late final AdminPayrollRepository adminPayrollRepository;
  late final AdminUserRepository adminUserRepository;
  late final MetaRepository metaRepository;
  late final ProfileRepository profileRepository;

  AppBootstrapState _state = AppBootstrapState.loading;
  String _baseUrl;
  String? _token;
  AppUser? _user;
  String? _errorMessage;
  bool _busy = false;

  AppBootstrapState get state => _state;
  String get baseUrl => _baseUrl;
  AppUser? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;
  bool get isAuthenticated => _state == AppBootstrapState.authenticated;

  Future<void> bootstrap() async {
    _state = AppBootstrapState.loading;
    _errorMessage = null;
    notifyListeners();
    final minimumStartup = Future<void>.delayed(_minimumStartupDuration);

    final snapshot = await _storage.load();
    _baseUrl = AppConfig.normalizeBaseUrl(snapshot.baseUrl);
    _token = snapshot.token;
    _user = snapshot.user;

    if (_token == null || _token!.isEmpty) {
      await minimumStartup;
      _state = AppBootstrapState.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await authRepository.me();
      await _storage.saveSession(token: _token!, user: _user!);
      await minimumStartup;
      _errorMessage = null;
      _state = AppBootstrapState.authenticated;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await clearSession();
      }

      await minimumStartup;
      _errorMessage = error.message;
      _user = null;
      _state = AppBootstrapState.unauthenticated;
    } catch (_) {
      await minimumStartup;
      _errorMessage =
          'Khong the khoi tao phien lam viec. Vui long thu lai sau.';
      _user = null;
      _state = AppBootstrapState.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> updateBaseUrl(String value) async {
    _baseUrl = AppConfig.normalizeBaseUrl(value);
    _errorMessage = null;
    await _storage.saveBaseUrl(_baseUrl);
    notifyListeners();
  }

  Future<bool> login({
    required String employeeCode,
    required String password,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authRepository.login(
        employeeCode: employeeCode,
        password: password,
      );

      _token = result.token;
      _user = result.user;
      await _storage.saveSession(token: result.token, user: result.user);
      _errorMessage = null;
      _state = AppBootstrapState.authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Khong the dang nhap luc nay. Vui long kiem tra ket noi va thu lai.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    final freshUser = await authRepository.me();
    _user = freshUser;

    if (_token != null) {
      await _storage.saveSession(token: _token!, user: freshUser);
    }

    notifyListeners();
  }

  Future<void> updateCurrentUser(AppUser value) async {
    _user = value;

    if (_token != null) {
      await _storage.saveSession(token: _token!, user: value);
    }

    notifyListeners();
  }

  Future<void> logout({bool remote = true}) async {
    try {
      if (remote && _token != null) {
        await authRepository.logout();
      }
    } catch (_) {
      // Best effort logout. Clearing local session is still required.
    } finally {
      await clearSession();
      _state = AppBootstrapState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> clearSession() async {
    _token = null;
    _user = null;
    _errorMessage = null;
    await _storage.clearSession();
  }
}
