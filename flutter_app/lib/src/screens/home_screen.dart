import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/attendance_record.dart';
import '../models/network_check_result.dart';
import '../models/shift_rule.dart';
import '../models/work_location.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<WorkLocation> _workLocations = const [];
  List<ShiftRule> _shiftRules = const [];
  List<AttendanceRecord> _todayRecords = const [];
  int? _selectedLocationId;
  NetworkCheckResult? _networkCheck;
  Position? _lastPosition;
  DateTime? _lastPositionCapturedAt;
  String? _lastPositionError;
  String _networkInfo = 'Chua kiem tra';
  DateTime _lastRefreshedAt = DateTime.now();

  WorkLocation? get _selectedLocation {
    for (final location in _workLocations) {
      if (location.id == _selectedLocationId) {
        return location;
      }
    }
    return _workLocations.isNotEmpty ? _workLocations.first : null;
  }

  ShiftRule? get _primaryShiftRule =>
      _shiftRules.isNotEmpty ? _shiftRules.first : null;

  AttendanceRecord? get _latestRecord =>
      _todayRecords.isNotEmpty ? _todayRecords.first : null;

  int get _validTodayCount =>
      _todayRecords.where((record) => record.status == 'valid').length;

  double? get _distanceToSelectedLocationM {
    final location = _selectedLocation;
    final position = _lastPosition;
    if (location == null || position == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      location.latitude,
      location.longitude,
    );
  }

  bool? get _isInsideSelectedLocation {
    final location = _selectedLocation;
    final distanceM = _distanceToSelectedLocationM;
    if (location == null || distanceM == null) {
      return null;
    }

    return distanceM <= location.radiusM;
  }

  bool? get _passesAccuracyRule {
    final position = _lastPosition;
    if (position == null) {
      return null;
    }

    return position.accuracy <= 100;
  }

  String get _nextActionHint {
    if (_todayRecords.isEmpty) {
      return 'San sang check-in';
    }

    final latest = _latestRecord!;
    return latest.checkType.contains('out')
        ? 'Cho moc check-in tiep theo'
        : 'Co the check-out neu dung khung gio';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final session = context.read<AppSession>();
      final locationsFuture = session.metaRepository.fetchWorkLocations();
      final shiftsFuture = session.metaRepository.fetchShiftRules();
      final attendanceFuture = session.attendanceRepository.fetchAttendance(
        date: DateTime.now(),
      );
      final networkFuture = _readNetworkInfo();

      final locations = await locationsFuture;
      final shifts = await shiftsFuture;
      final records = await attendanceFuture;
      final networkInfo = await networkFuture;

      if (!mounted) {
        return;
      }

      final hasSelectedLocation = locations.any(
        (location) => location.id == _selectedLocationId,
      );

      setState(() {
        _workLocations = locations;
        _shiftRules = shifts;
        _todayRecords = records.data;
        _networkInfo = networkInfo;
        _selectedLocationId =
            hasSelectedLocation
                ? _selectedLocationId
                : (locations.isNotEmpty ? locations.first.id : null);
        _errorMessage = null;
        _lastRefreshedAt = DateTime.now();
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _readNetworkInfo() async {
    final statuses = await Connectivity().checkConnectivity();
    return connectivityLabel(statuses);
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dich vu vi tri dang tat. Hay bat GPS roi thu lai.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Ung dung chua duoc cap quyen vi tri.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyen vi tri da bi tu choi vinh vien. Hay mo cai dat ung dung de cap lai.',
      );
    }
  }

  Future<Position> _capturePosition() async {
    await _ensureLocationPermission();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  void _rememberPosition(Position position) {
    _lastPosition = position;
    _lastPositionCapturedAt = position.timestamp.toLocal();
    _lastPositionError = null;
  }

  Future<void> _tryCapturePositionSnapshot() async {
    try {
      final position = await _capturePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _rememberPosition(position);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lastPositionError = error.toString();
      });
    }
  }

  Future<void> _refreshPositionPreview() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final position = await _capturePosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _rememberPosition(position);
      });

      AppToast.info(
        'Da cap nhat GPS',
        message: 'Vi tri hien tai da duoc lay de doi chieu geofence.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lastPositionError = error.toString();
      });

      AppToast.warning('Khong lay duoc GPS', message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _readDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      final info = await deviceInfo.webBrowserInfo;
      return 'Web ${info.browserName.toString().split('.').last}';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      case TargetPlatform.iOS:
        final info = await deviceInfo.iosInfo;
        return '${info.name} (${info.systemVersion})';
      case TargetPlatform.windows:
        final info = await deviceInfo.windowsInfo;
        return '${info.computerName} (${info.displayVersion})';
      case TargetPlatform.macOS:
        final info = await deviceInfo.macOsInfo;
        return '${info.computerName} (${info.osRelease})';
      case TargetPlatform.linux:
        final info = await deviceInfo.linuxInfo;
        return '${info.name} (${info.version ?? info.prettyName})';
      case TargetPlatform.fuchsia:
        return 'Fuchsia device';
    }
  }

  Color _statusColor(String status) {
    return status == 'valid'
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
  }

  Future<void> _runNetworkCheck() async {
    final location = _selectedLocation;
    if (location == null) {
      AppToast.warning(
        'Chua co dia diem',
        message: 'Hay chon mot dia diem cham cong truoc khi kiem tra mang.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = context.read<AppSession>();
      final networkInfo = await _readNetworkInfo();
      await _tryCapturePositionSnapshot();
      final result = await session.attendanceRepository.networkCheck(
        workLocationId: location.id,
        networkInfo: networkInfo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _networkInfo = networkInfo;
        _networkCheck = result;
      });

      AppToast.info(
        result.isAllowed ? 'Mang hop le' : 'Mang chua hop le',
        message: result.message,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.payload.containsKey('data')) {
        setState(() {
          _networkCheck = NetworkCheckResult.fromJson(error.payload);
        });
      }

      AppToast.warning('Kiem tra mang that bai', message: error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitAttendance({required bool isCheckIn}) async {
    final location = _selectedLocation;
    if (location == null) {
      AppToast.warning(
        'Chua co dia diem',
        message: 'Hay chon dia diem lam viec truoc khi cham cong.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = context.read<AppSession>();
      final networkInfo = await _readNetworkInfo();
      late final Position position;
      try {
        position = await _capturePosition();
      } catch (error) {
        if (mounted) {
          setState(() {
            _lastPositionError = error.toString();
          });
        }
        rethrow;
      }

      if (mounted) {
        setState(() {
          _rememberPosition(position);
        });
      }

      final deviceInfo = await _readDeviceInfo();

      final result = await session.attendanceRepository.submitAttendance(
        isCheckIn: isCheckIn,
        workLocationId: location.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
        networkInfo: networkInfo,
        deviceInfo: deviceInfo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _networkInfo = networkInfo;
      });

      await _loadDashboard(silent: true);

      if (!mounted) {
        return;
      }

      AppToast.success(
        isCheckIn ? 'Check-in thanh cong' : 'Check-out thanh cong',
        message: result.message,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.payload.containsKey('data')) {
        setState(() {
          _networkCheck = NetworkCheckResult.fromJson(error.payload);
        });
      }

      AppToast.warning(
        isCheckIn ? 'Check-in that bai' : 'Check-out that bai',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
    required IconData icon,
    Color accentColor = const Color(0xFF60A5FA),
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWindow({
    required String label,
    required String start,
    required String end,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${formatTime(start)} - ${formatTime(end)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(AttendanceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _statusColor(record.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              record.status == 'valid'
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: _statusColor(record.status),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        attendanceTypeLabel(record.checkType),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusBadge(
                      label: statusLabel(record.status),
                      color: _statusColor(record.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatDate(record.checkDate)} | ${formatTime(record.checkTime)}',
                ),
                if (record.workLocation != null) ...[
                  const SizedBox(height: 4),
                  Text(record.workLocation!.name),
                ],
                const SizedBox(height: 4),
                Text(
                  'Khoang cach: ${formatMeters(record.distanceM)} | GPS: ${formatMeters(record.accuracyM)}',
                ),
                if ((record.reason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(reasonLabel(record.reason)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final user = session.user;
    final selectedLocation = _selectedLocation;
    final shiftRule = _primaryShiftRule;

    if (_isLoading && _workLocations.isEmpty && _todayRecords.isEmpty) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1E40AF),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chao, ${user?.name ?? 'nhan vien'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ma NV: ${user?.employeeCode ?? '--'} | Cap nhat: ${formatDateTime(_lastRefreshedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusBadge(
                        label: user?.role ?? 'Employee',
                        color: const Color(0xFFDBEAFE),
                      ),
                      StatusBadge(
                        label: user?.department ?? 'No department',
                        color: const Color(0xFFFEF3C7),
                      ),
                      StatusBadge(
                        label: _nextActionHint,
                        color: const Color(0xFFF3E8FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            session.baseUrl,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStat(
                          label: 'Ban ghi hop le hom nay',
                          value: '$_validTodayCount',
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeroStat(
                          label: 'Ket noi hien tai',
                          value: _networkInfo,
                          icon: Icons.wifi_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (_isSubmitting) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ],
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Can kiem tra lai',
                subtitle: 'Khong tai duoc du lieu dashboard',
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!)),
                    TextButton(
                      onPressed: _loadDashboard,
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              title: 'Dia diem cham cong',
              subtitle: 'Chon dia diem lam viec dang ap dung',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedLocation?.id,
                    items: _workLocations
                        .map(
                          (location) => DropdownMenuItem<int>(
                            value: location.id,
                            child: Text(location.name),
                          ),
                        )
                        .toList(growable: false),
                    hint: const Text('Chon dia diem'),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocationId = value;
                      });
                    },
                  ),
                  if (selectedLocation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLocation.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if ((selectedLocation.address ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(selectedLocation.address!),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Toa do: ${selectedLocation.latitude.toStringAsFixed(5)}, ${selectedLocation.longitude.toStringAsFixed(5)}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ban kinh cho phep: ${selectedLocation.radiusM} m',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Hanh dong nhanh',
              subtitle: 'Kiem tra mang va cham cong ngay tren mot cum thao tac',
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ket noi hien tai: $_networkInfo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            StatusBadge(
                              label:
                                  _networkCheck?.isAllowed == true
                                      ? 'Hop le'
                                      : (_networkCheck == null
                                          ? 'Chua check'
                                          : 'Can xem lai'),
                              color:
                                  _networkCheck?.isAllowed == true
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_lastPosition != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS hien tai: ${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cap nhat: ${formatDateTime(_lastPositionCapturedAt)}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Do chinh xac GPS: ${formatMeters(_lastPosition!.accuracy)} (${_passesAccuracyRule == true ? 'Dat rule <= 100 m' : 'Chua dat rule <= 100 m'})',
                              ),
                              if (selectedLocation != null &&
                                  _distanceToSelectedLocationM != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Khoang cach toi ${selectedLocation.name}: ${formatMeters(_distanceToSelectedLocationM)} / gioi han ${selectedLocation.radiusM} m',
                                ),
                                const SizedBox(height: 8),
                                StatusBadge(
                                  label:
                                      _isInsideSelectedLocation == true
                                          ? 'Trong pham vi'
                                          : 'Ngoai pham vi',
                                  color:
                                      _isInsideSelectedLocation == true
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEE2E2),
                                ),
                              ],
                              if (_lastPosition!.isMocked) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Canh bao: thiet bi dang tra ve vi tri mocked/gia lap.',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          const Text('Chua lay GPS trong phien hien tai.'),
                        if ((_lastPositionError ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Khong lay duoc GPS: $_lastPositionError',
                            style: const TextStyle(color: Color(0xFFB91C1C)),
                          ),
                        ],
                        if (_networkCheck != null) ...[
                          const SizedBox(height: 8),
                          Text(_networkCheck!.message),
                          if ((_networkCheck!.allowedNetwork ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Allowed network: ${_networkCheck!.allowedNetwork}',
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _refreshPositionPreview,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Lay GPS hien tai'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _runNetworkCheck,
                          icon: const Icon(Icons.wifi_find_rounded),
                          label: const Text('Kiem tra mang'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed:
                              _isSubmitting || selectedLocation == null
                                  ? null
                                  : () => _submitAttendance(isCheckIn: true),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Check-in'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _isSubmitting || selectedLocation == null
                              ? null
                              : () => _submitAttendance(isCheckIn: false),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Check-out'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Khung gio ap dung',
              subtitle: shiftRule?.name ?? 'Chua co ca lam viec dang bat',
              child:
                  shiftRule == null
                      ? const Text('Backend chua tra ve quy tac ca lam viec.')
                      : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeWindow(
                                  label: 'Vao ca sang',
                                  start: shiftRule.morningCheckInStart,
                                  end: shiftRule.morningCheckInEnd,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeWindow(
                                  label: 'Ra ca sang',
                                  start: shiftRule.morningCheckOutStart,
                                  end: shiftRule.morningCheckOutEnd,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeWindow(
                                  label: 'Vao ca chieu',
                                  start: shiftRule.afternoonCheckInStart,
                                  end: shiftRule.afternoonCheckInEnd,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeWindow(
                                  label: 'Ra ca chieu',
                                  start: shiftRule.afternoonCheckOutStart,
                                  end: shiftRule.afternoonCheckOutEnd,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Lich su hom nay',
              subtitle: 'Tom tat cac moc da ghi nhan trong ngay hien tai',
              child:
                  _todayRecords.isEmpty
                      ? const Text('Hom nay chua co ban ghi cham cong.')
                      : Column(
                        children: _todayRecords
                            .map(_buildAttendanceTile)
                            .toList(growable: false),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
