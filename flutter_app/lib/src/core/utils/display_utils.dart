import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime? value, {String pattern = 'dd/MM/yyyy'}) {
  if (value == null) {
    return '--';
  }
  return DateFormat(pattern).format(value.toLocal());
}

String formatDateTime(DateTime? value, {String pattern = 'dd/MM/yyyy HH:mm'}) {
  if (value == null) {
    return '--';
  }
  return DateFormat(pattern).format(value.toLocal());
}

String formatTime(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '--';
  }
  if (raw.length >= 5) {
    return raw.substring(0, 5);
  }
  return raw;
}

String formatMeters(double? value) {
  if (value == null) {
    return '--';
  }
  final hasDecimal = value.truncateToDouble() != value;
  return '${value.toStringAsFixed(hasDecimal ? 1 : 0)} m';
}

String attendanceTypeLabel(String? value) {
  return switch (value) {
    'morning_check_in' => 'Vao ca sang',
    'morning_check_out' => 'Ra ca sang',
    'afternoon_check_in' => 'Vao ca chieu',
    'afternoon_check_out' => 'Ra ca chieu',
    _ => value ?? '--',
  };
}

String reasonLabel(String? value) {
  return switch (value) {
    'wrong_time_window' => 'Khong nam trong khung gio cham cong hop le.',
    'duplicate_check' => 'Moc cham cong nay da duoc ghi nhan truoc do.',
    'missing_check_in' => 'Ban chua check-in cho ca tuong ung.',
    'low_accuracy' => 'GPS chua du chinh xac, vui long thu lai.',
    'outside_geofence' => 'Vi tri hien tai nam ngoai khu vuc cho phep.',
    'wrong_network' => 'Thiet bi chua ket noi dung mang hop le.',
    _ => value ?? '--',
  };
}

String statusLabel(String? status) {
  return switch (status) {
    'valid' => 'Hop le',
    'invalid' => 'Khong hop le',
    _ => status ?? '--',
  };
}

String connectivityLabel(List<ConnectivityResult> results) {
  final names = results
      .where((result) => result != ConnectivityResult.none)
      .map(
        (result) => switch (result) {
          ConnectivityResult.wifi => 'Wi-Fi',
          ConnectivityResult.mobile => 'Di dong',
          ConnectivityResult.ethernet => 'Ethernet',
          ConnectivityResult.bluetooth => 'Bluetooth',
          ConnectivityResult.satellite => 'Ve tinh',
          ConnectivityResult.vpn => 'VPN',
          ConnectivityResult.other => 'Mang khac',
          ConnectivityResult.none => 'Khong co mang',
        },
      )
      .toSet()
      .toList(growable: false);

  if (names.isEmpty) {
    return 'Khong co mang';
  }

  return names.join(', ');
}
