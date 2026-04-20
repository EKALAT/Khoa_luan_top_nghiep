import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/attendance_log.dart';
import '../models/attendance_record.dart';
import '../models/paginated_response.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  PaginatedResponse<AttendanceRecord>? _recordsPage;
  PaginatedResponse<AttendanceLog>? _logsPage;
  bool _recordsLoading = true;
  bool _logsLoading = true;
  String? _recordsError;
  String? _logsError;
  DateTime? _selectedDate;
  String? _statusFilter;
  String? _checkTypeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
      _loadLogs();
    });
  }

  Future<void> _loadRecords({int page = 1}) async {
    setState(() {
      _recordsLoading = true;
      _recordsError = null;
    });
    try {
      final session = context.read<AppSession>();
      final response = await session.attendanceRepository.fetchAttendance(
        date: _selectedDate,
        status: _statusFilter,
        checkType: _checkTypeFilter,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _recordsPage = response;
        _recordsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _recordsError = error.message;
        _recordsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recordsError = error.toString();
        _recordsLoading = false;
      });
    }
  }

  Future<void> _loadLogs({int page = 1}) async {
    setState(() {
      _logsLoading = true;
      _logsError = null;
    });
    try {
      final session = context.read<AppSession>();
      final response = await session.attendanceRepository.fetchLogs(page: page);
      if (!mounted) return;
      setState(() {
        _logsPage = response;
        _logsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _logsError = error.message;
        _logsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _logsError = error.toString();
        _logsLoading = false;
      });
    }
  }

  Color _statusColor(String status) =>
      status == 'valid' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _loadRecords();
  }

  Widget _pagination({
    required int currentPage,
    required int lastPage,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Truoc'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Trang $currentPage/$lastPage'),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Sau'),
          ),
        ),
      ],
    );
  }

  Widget _recordTile(AttendanceRecord record) {
    final color = _statusColor(record.status);
    final actorName = _actorName(
      employeeName: record.employeeName,
      fallback: 'Nhan vien',
    );
    final actorCode = _actorCode(employeeCode: record.employeeCode);
    final actorDepartment = _actorDepartment(
      employeeDepartment: record.employeeDepartment,
    );
    final avatarUrl = _actorAvatarUrl(
      employeeAvatarUrl: record.employeeAvatarUrl,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actorHeader(
            name: actorName,
            employeeCode: actorCode,
            department: actorDepartment,
            avatarUrl: avatarUrl,
            badge: StatusBadge(
              label: statusLabel(record.status),
              color: color,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  record.status == 'valid'
                      ? Icons.task_alt_rounded
                      : Icons.warning_amber_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendanceTypeLabel(record.checkType),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatDate(record.checkDate)} | ${formatTime(record.checkTime)}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    if (record.workLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.workLocation!.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Khoang cach ${formatMeters(record.distanceM)} | GPS ${formatMeters(record.accuracyM)}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    if ((record.reason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reasonLabel(record.reason),
                        style: const TextStyle(color: Color(0xFFB45309)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logTile(AttendanceLog log) {
    final color = _statusColor(log.result);
    final actorName = _actorName(
      employeeName: log.employeeName,
      fallback: 'Nhan vien',
    );
    final actorCode = _actorCode(employeeCode: log.employeeCode);
    final actorDepartment = _actorDepartment(
      employeeDepartment: log.employeeDepartment,
    );
    final avatarUrl = _actorAvatarUrl(
      employeeAvatarUrl: log.employeeAvatarUrl,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actorHeader(
            name: actorName,
            employeeCode: actorCode,
            department: actorDepartment,
            avatarUrl: avatarUrl,
            badge: StatusBadge(label: statusLabel(log.result), color: color),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  log.attendanceRecord == null
                      ? formatDateTime(log.capturedAt)
                      : '${attendanceTypeLabel(log.attendanceRecord!.checkType)} | ${formatDateTime(log.capturedAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              'GPS ${log.lat.toStringAsFixed(5)}, ${log.lng.toStringAsFixed(5)} | ${formatMeters(log.accuracyM)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          if ((log.networkInfo ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.networkInfo!,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
          if ((log.deviceInfo ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.deviceInfo!,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
          if ((log.reason ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reasonLabel(log.reason),
              style: const TextStyle(color: Color(0xFFB45309)),
            ),
          ],
        ],
      ),
      );
  }

  String _actorName({String? employeeName, required String fallback}) {
    if ((employeeName ?? '').trim().isNotEmpty) {
      return employeeName!.trim();
    }

    final currentUser = context.read<AppSession>().user;
    final fallbackName = (currentUser?.name ?? '').trim();
    return fallbackName.isNotEmpty ? fallbackName : fallback;
  }

  String? _actorCode({String? employeeCode}) {
    if ((employeeCode ?? '').trim().isNotEmpty) {
      return employeeCode!.trim();
    }

    final currentUser = context.read<AppSession>().user;
    final fallbackCode = (currentUser?.employeeCode ?? '').trim();
    return fallbackCode.isEmpty ? null : fallbackCode;
  }

  String? _actorDepartment({String? employeeDepartment}) {
    if ((employeeDepartment ?? '').trim().isNotEmpty) {
      return employeeDepartment!.trim();
    }

    final currentUser = context.read<AppSession>().user;
    final fallbackDepartment = (currentUser?.department ?? '').trim();
    return fallbackDepartment.isEmpty ? null : fallbackDepartment;
  }

  String? _actorAvatarUrl({String? employeeAvatarUrl}) {
    if ((employeeAvatarUrl ?? '').trim().isNotEmpty) {
      return employeeAvatarUrl!.trim();
    }

    final currentUser = context.read<AppSession>().user;
    final fallbackAvatar = (currentUser?.avatarUrl ?? '').trim();
    return fallbackAvatar.isEmpty ? null : fallbackAvatar;
  }

  Widget _actorHeader({
    required String name,
    required String? employeeCode,
    required String? department,
    required String? avatarUrl,
    required Widget badge,
  }) {
    final subtitleParts = <String>[
      if ((employeeCode ?? '').trim().isNotEmpty) employeeCode!.trim(),
      if ((department ?? '').trim().isNotEmpty) department!.trim(),
    ];
    final avatarProvider =
        (avatarUrl ?? '').isEmpty ? null : NetworkImage(avatarUrl!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFDBEAFE),
          backgroundImage: avatarProvider,
          child: avatarProvider == null
              ? Text(
                  name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' | '),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        badge,
      ],
    );
  }

  Widget _buildRecordList() {
    if (_recordsLoading && _recordsPage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recordsError != null && _recordsPage == null) {
      return Center(child: Text(_recordsError!));
    }
    final page = _recordsPage;
    if (page == null || page.data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Khong co ban ghi phu hop voi bo loc hien tai.'),
      );
    }
    return Column(
      children: [
        ...page.data.map(_recordTile),
        const SizedBox(height: 8),
        _pagination(
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          onPrevious:
              page.currentPage > 1
                  ? () => _loadRecords(page: page.currentPage - 1)
                  : null,
          onNext:
              page.currentPage < page.lastPage
                  ? () => _loadRecords(page: page.currentPage + 1)
                  : null,
        ),
      ],
    );
  }

  Widget _buildLogList() {
    if (_logsLoading && _logsPage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logsError != null && _logsPage == null) {
      return Center(child: Text(_logsError!));
    }
    final page = _logsPage;
    if (page == null || page.data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Chua co log cham cong nao.'),
      );
    }
    return Column(
      children: [
        ...page.data.map(_logTile),
        const SizedBox(height: 8),
        _pagination(
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          onPrevious:
              page.currentPage > 1
                  ? () => _loadLogs(page: page.currentPage - 1)
                  : null,
          onNext:
              page.currentPage < page.lastPage
                  ? () => _loadLogs(page: page.currentPage + 1)
                  : null,
        ),
      ],
    );
  }

  Widget _historyFilters() {
    final clearDateButton =
        _selectedDate == null
            ? null
            : IconButton.filledTonal(
                onPressed: () {
                  setState(() => _selectedDate = null);
                  _loadRecords();
                },
                icon: const Icon(Icons.close_rounded),
              );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactFilters = constraints.maxWidth < 360;

        final dateButton = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text(
              _selectedDate == null ? 'Loc theo ngay' : formatDate(_selectedDate),
            ),
          ),
        );

        final statusDropdown = DropdownButtonFormField<String?>(
          isDense: true,
          value: _statusFilter,
          decoration: const InputDecoration(labelText: 'Trang thai'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Tat ca'),
            ),
            DropdownMenuItem<String?>(
              value: 'valid',
              child: Text('Hop le'),
            ),
            DropdownMenuItem<String?>(
              value: 'invalid',
              child: Text('Khong hop le'),
            ),
          ],
          onChanged: (value) {
            setState(() => _statusFilter = value);
            _loadRecords();
          },
        );

        final checkTypeDropdown = DropdownButtonFormField<String?>(
          isDense: true,
          value: _checkTypeFilter,
          decoration: const InputDecoration(labelText: 'Moc cham cong'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Tat ca'),
            ),
            DropdownMenuItem<String?>(
              value: 'morning_check_in',
              child: Text('Vao ca sang'),
            ),
            DropdownMenuItem<String?>(
              value: 'morning_check_out',
              child: Text('Ra ca sang'),
            ),
            DropdownMenuItem<String?>(
              value: 'afternoon_check_in',
              child: Text('Vao ca chieu'),
            ),
            DropdownMenuItem<String?>(
              value: 'afternoon_check_out',
              child: Text('Ra ca chieu'),
            ),
          ],
          onChanged: (value) {
            setState(() => _checkTypeFilter = value);
            _loadRecords();
          },
        );

        return Column(
          children: [
            if (compactFilters) ...[
              if (clearDateButton == null)
                dateButton
              else
                Row(
                  children: [
                    Expanded(child: dateButton),
                    const SizedBox(width: 10),
                    clearDateButton,
                  ],
                ),
              const SizedBox(height: 12),
              statusDropdown,
              const SizedBox(height: 12),
              checkTypeDropdown,
            ] else ...[
              Row(
                children: [
                  Expanded(child: dateButton),
                  if (clearDateButton != null) ...[
                    const SizedBox(width: 10),
                    clearDateButton,
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: statusDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: checkTypeDropdown),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TabBar(
              labelPadding: EdgeInsets.symmetric(
                horizontal: compactFilters ? 8 : 16,
              ),
              tabs: const [Tab(text: 'Ban ghi'), Tab(text: 'Log')],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = context.watch<AppSession>().user;
    final isAdmin = sessionUser?.roleCode == 'admin';
    final recordCount = _recordsPage?.data.length ?? 0;
    final logCount = _logsPage?.data.length ?? 0;
    final compactTopSection = MediaQuery.sizeOf(context).height < 780;

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                compactTopSection ? 8 : 12,
                16,
                0,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compactTopSection ? 20 : 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x261E40AF),
                          blurRadius: 22,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lich su cham cong',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAdmin
                              ? 'Theo doi lich su cham cong cua toan bo nhan vien, kem avatar, ten day du va log thiet bi trong cung mot giao dien.'
                              : 'Theo doi ban ghi hop le, ban ghi can xem lai va log thiet bi trong cung mot giao dien.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: compactTopSection ? 12 : 16),
                        Wrap(
                          spacing: compactTopSection ? 8 : 10,
                          runSpacing: compactTopSection ? 8 : 10,
                          children: [
                            StatusBadge(
                              label: '$recordCount ban ghi tren trang',
                              color: const Color(0xFFDBEAFE),
                            ),
                            StatusBadge(
                              label: '$logCount log tren trang',
                              color: const Color(0xFFFEF3C7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compactTopSection ? 12 : 16),
                  SectionCard(
                    title: 'Bo loc va che do xem',
                    subtitle:
                        'Loc nhanh theo ngay, trang thai va moc cham cong.',
                    child: _historyFilters(),
                  ),
                ],
              ),
            ),
            SizedBox(height: compactTopSection ? 12 : 16),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      children: [_buildRecordList()],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      children: [_buildLogList()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
