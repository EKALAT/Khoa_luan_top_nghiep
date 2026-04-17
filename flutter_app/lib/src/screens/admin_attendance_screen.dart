import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/admin_attendance_moment.dart';
import '../models/admin_attendance_overview.dart';
import '../models/admin_attendance_user.dart';
import '../models/department_option.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final _searchController = TextEditingController();

  AdminAttendanceOverview? _overview;
  List<DepartmentOption> _departments = const [];
  bool _loading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  int? _departmentIdFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = context.read<AppSession>();
      final departmentsFuture = session.metaRepository.fetchDepartments();
      final overviewFuture = session.adminAttendanceRepository.fetchOverview(
        date: _selectedDate,
      );

      final departments = await departmentsFuture;
      final overview = await overviewFuture;

      if (!mounted) return;

      setState(() {
        _departments = departments;
        _overview = overview;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadOverview({int page = 1, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final session = context.read<AppSession>();
      final overview = await session.adminAttendanceRepository.fetchOverview(
        date: _selectedDate,
        search: _searchController.text,
        departmentId: _departmentIdFilter,
        status: _statusFilter,
        page: page,
      );

      if (!mounted) return;

      setState(() {
        _overview = overview;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedDate = picked);
    await _loadOverview();
  }

  String _attendanceStatusLabel(String value) {
    return switch (value) {
      'not_checked_in' => 'Chua cham',
      'partial' => 'Dang trong ngay',
      'completed' => 'Hoan thanh',
      _ => value,
    };
  }

  Color _attendanceStatusColor(String value) {
    return switch (value) {
      'not_checked_in' => const Color(0xFFFEE2E2),
      'partial' => const Color(0xFFFEF3C7),
      'completed' => const Color(0xFFDCFCE7),
      _ => const Color(0xFFE2E8F0),
    };
  }

  Widget _summaryStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _momentChip(AdminAttendanceMoment moment) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            attendanceTypeLabel(moment.checkType),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            formatTime(moment.checkTime),
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          if ((moment.workLocationName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              moment.workLocationName!,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _userCard(AdminAttendanceUser user) {
    final avatarProvider =
        (user.avatarUrl ?? '').isEmpty ? null : NetworkImage(user.avatarUrl!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        user.name.trim().isEmpty
                            ? '?'
                            : user.name.trim()[0].toUpperCase(),
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
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.employeeCode,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: _attendanceStatusLabel(user.attendanceStatus),
                          color: _attendanceStatusColor(user.attendanceStatus),
                        ),
                        StatusBadge(
                          label:
                              '${user.validRecordCount}/${_overview?.summary.expectedValidRecords ?? 4} moc',
                          color: const Color(0xFFDBEAFE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Phong ban: ${user.department ?? 'Chua gan'}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Lan dang nhap: ${formatDateTime(user.lastLoginAt)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            user.latestCheckTime == null
                ? 'Hom nay chua co moc cham cong hop le.'
                : 'Gan nhat: ${attendanceTypeLabel(user.latestCheckType)} luc ${formatTime(user.latestCheckTime)}',
            style: TextStyle(
              color: user.latestCheckTime == null
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF0F172A),
              fontWeight: user.latestCheckTime == null
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          if (user.todayRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Chua ghi nhan moc cham cong hop le nao trong ngay da chon.',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Wrap(
              children: user.todayRecords.map(_momentChip).toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _pagination() {
    final page = _overview?.page;
    if (page == null || page.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: page.currentPage > 1
                ? () => _loadOverview(page: page.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Truoc'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Trang ${page.currentPage}/${page.lastPage}'),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: page.currentPage < page.lastPage
                ? () => _loadOverview(page: page.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Sau'),
          ),
        ),
      ],
    );
  }

  Widget _filterSection(AdminAttendanceOverview? overview) {
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
            label: Text(formatDate(_selectedDate)),
          ),
        );

        final searchField = TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loadOverview(),
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Tim nhan vien',
            hintText: 'VD: nv001, System Admin',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: () => _loadOverview(),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        );

        final departmentDropdown = DropdownButtonFormField<int?>(
          isDense: true,
          value: _departmentIdFilter,
          decoration: const InputDecoration(labelText: 'Phong ban'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Tat ca phong ban'),
            ),
            ..._departments.map(
              (department) => DropdownMenuItem<int?>(
                value: department.id,
                child: Text(department.name),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _departmentIdFilter = value);
            _loadOverview();
          },
        );

        final statusDropdown = DropdownButtonFormField<String?>(
          isDense: true,
          value: _statusFilter,
          decoration: const InputDecoration(labelText: 'Tinh trang'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Tat ca'),
            ),
            DropdownMenuItem<String?>(
              value: 'not_checked_in',
              child: Text('Chua cham'),
            ),
            DropdownMenuItem<String?>(
              value: 'partial',
              child: Text('Dang trong ngay'),
            ),
            DropdownMenuItem<String?>(
              value: 'completed',
              child: Text('Hoan thanh'),
            ),
          ],
          onChanged: (value) {
            setState(() => _statusFilter = value);
            _loadOverview();
          },
        );

        return Column(
          children: [
            if (compactFilters) ...[
              dateButton,
              const SizedBox(height: 12),
              searchField,
              const SizedBox(height: 12),
              departmentDropdown,
              const SizedBox(height: 12),
              statusDropdown,
            ] else ...[
              Row(
                children: [
                  Expanded(child: dateButton),
                  const SizedBox(width: 10),
                  Expanded(child: searchField),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: departmentDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: statusDropdown),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Moc hoan thanh hien tai: ${overview?.summary.expectedValidRecords ?? 4} ban ghi hop le trong ngay.',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _overview == null) {
      final loadingBody = const Center(child: CircularProgressIndicator());
      return widget.embedded ? loadingBody : SafeArea(child: loadingBody);
    }

    final overview = _overview;
    final users = overview?.page.data ?? const <AdminAttendanceUser>[];

    final body = RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33134E4A),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cham cong theo ngay',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Theo doi ai da cham, ai chua cham va ai da hoan thanh du 4 moc trong ngay.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Tong nhan su',
                        value: '${overview?.summary.totalUsers ?? 0}',
                        color: const Color(0xFFE0F2FE),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Da cham it nhat 1 moc',
                        value: '${overview?.summary.checkedInCount ?? 0}',
                        color: const Color(0xFFDBEAFE),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Chua cham',
                        value: '${overview?.summary.notCheckedInCount ?? 0}',
                        color: const Color(0xFFFECACA),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Hoan thanh',
                        value: '${overview?.summary.completedCount ?? 0}',
                        color: const Color(0xFFBBF7D0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bo loc va che do xem',
            subtitle:
                'Tim nhan vien theo ngay, phong ban va tinh trang cham cong.',
            child: _filterSection(overview),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Can kiem tra lai',
              subtitle: 'Khong tai duoc tinh hinh cham cong hien tai.',
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_errorMessage!)),
                  TextButton(
                    onPressed: _bootstrap,
                    child: const Text('Thu lai'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: 'Danh sach cham cong',
            subtitle: 'Tong hop theo ngay da chon va bo loc hien tai.',
            child: users.isEmpty
                ? const Text(
                    'Khong co nhan vien phu hop voi bo loc hien tai.',
                  )
                : Column(
                    children: users.map(_userCard).toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          _pagination(),
        ],
      ),
    );

    return widget.embedded ? body : SafeArea(child: body);
  }
}
