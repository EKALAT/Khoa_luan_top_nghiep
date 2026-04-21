import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../core/utils/file_download.dart';
import '../models/admin_monthly_attendance_day.dart';
import '../models/admin_monthly_attendance_overview.dart';
import '../models/admin_monthly_attendance_user.dart';
import '../models/department_option.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class AdminMonthlyAttendanceScreen extends StatefulWidget {
  const AdminMonthlyAttendanceScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminMonthlyAttendanceScreen> createState() =>
      _AdminMonthlyAttendanceScreenState();
}

class _AdminMonthlyAttendanceScreenState
    extends State<AdminMonthlyAttendanceScreen> {
  final _searchController = TextEditingController();
  final _matrixHorizontalController = ScrollController();

  AdminMonthlyAttendanceOverview? _overview;
  List<DepartmentOption> _departments = const [];
  bool _loading = true;
  bool _exporting = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();
  int? _departmentIdFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _matrixHorizontalController.dispose();
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
      final overviewFuture = session.adminAttendanceRepository.fetchMonthlyOverview(
        month: _selectedMonth,
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
      final overview = await session.adminAttendanceRepository.fetchMonthlyOverview(
        month: _selectedMonth,
        search: _searchController.text,
        departmentId: _departmentIdFilter,
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    await _loadOverview();
  }

  Future<void> _exportCsv() async {
    if (_exporting) {
      return;
    }

    if (!kIsWeb) {
      AppToast.info(
        'Nen test tren web',
        message:
            'Chuc nang xuat bang cong hien duoc toi uu de tai file truc tiep tren Flutter Web.',
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final session = context.read<AppSession>();
      final bytes = await session.adminAttendanceRepository.exportMonthlyOverviewCsv(
        month: _selectedMonth,
        search: _searchController.text,
        departmentId: _departmentIdFilter,
      );

      final filename =
          'bang_cong_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.csv';

      await downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'text/csv;charset=utf-8',
      );

      AppToast.success(
        'Xuat bang cong thanh cong',
        message: 'Trinh duyet dang tai file $filename',
      );
    } on ApiException catch (error) {
      AppToast.warning('Xuat bang cong that bai', message: error.message);
    } on UnsupportedError catch (error) {
      AppToast.warning('Khong the tai file', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _formatMonthLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '$month/${value.year}';
  }

  String _formatWorkUnits(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatWorkUnitsCell(double value) {
    return value.toStringAsFixed(1);
  }

  String _dayStatusLabel(String status) {
    return switch (status) {
      'full_day' => 'Du cong',
      'half_day' => 'Nua cong',
      'incomplete' => 'Chua du',
      'not_recorded' => 'Chua ghi nhan',
      _ => status,
    };
  }

  Color _dayStatusColor(String status) {
    return switch (status) {
      'full_day' => const Color(0xFFDCFCE7),
      'half_day' => const Color(0xFFDBEAFE),
      'incomplete' => const Color(0xFFFEF3C7),
      'not_recorded' => const Color(0xFFF1F5F9),
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

  Widget _momentChip(AdminMonthlyAttendanceDay day) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: day.moments
          .map(
            (moment) => StatusBadge(
              label:
                  '${attendanceTypeLabel(moment.checkType)} ${formatTime(moment.checkTime)}',
              color: const Color(0xFFF8FAFC),
            ),
          )
          .toList(growable: false),
    );
  }

  List<DateTime> _trackedDates() {
    final summary = _overview?.summary;
    if (summary == null || summary.rangeEnd == null) {
      return const [];
    }

    final monthDate = DateTime.tryParse('${summary.month}-01');
    final rangeEnd = DateTime.tryParse(summary.rangeEnd!);

    if (monthDate == null || rangeEnd == null) {
      return const [];
    }

    final dates = <DateTime>[];
    var cursor = DateTime(monthDate.year, monthDate.month, 1);

    while (!cursor.isAfter(rangeEnd)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  Future<void> _showMonthlyDetails(AdminMonthlyAttendanceUser user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name} - Bang cong thang',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.employeeCode} | Tong cong ${_formatWorkUnits(user.totalWorkUnits)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: user.dailyBreakdown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final day = user.dailyBreakdown[index];
                      final date = DateTime.tryParse(day.date);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatDate(date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                StatusBadge(
                                  label: _dayStatusLabel(day.status),
                                  color: _dayStatusColor(day.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cong trong ngay: ${_formatWorkUnits(day.workUnits)} | Moc hop le: ${day.validRecordCount}',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (day.moments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _momentChip(day),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeaderCell({
    required double width,
    required String label,
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: width,
      height: 52,
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _tableValueCell({
    required String value,
    required double width,
    required Color backgroundColor,
    required Color foregroundColor,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return Container(
      width: width,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 13,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _tableNameCell(AdminMonthlyAttendanceUser user, double width) {
    final avatarProvider =
        (user.avatarUrl ?? '').isEmpty ? null : NetworkImage(user.avatarUrl!);

    return Container(
      width: width,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDBEAFE),
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? Text(
                    user.name.trim().isEmpty
                        ? '?'
                        : user.name.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.employeeCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrixTable(List<AdminMonthlyAttendanceUser> users) {
    final trackedDates = _trackedDates();
    final nameWidth = 220.0;
    final dayWidth = 54.0;
    final totalWidth = 82.0;

    if (trackedDates.isEmpty) {
      return const Text(
        'Chua co du lieu ngay trong thang duoc chon de lap bang cong.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cham vao tung dong de xem chi tiet cong theo ngay.',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScrollbarTheme(
                data: ScrollbarTheme.of(context).copyWith(
                  thumbColor: WidgetStateProperty.all(const Color(0xFF94A3B8)),
                  trackColor: WidgetStateProperty.all(
                    const Color(0xFFE2E8F0),
                  ),
                  trackBorderColor: WidgetStateProperty.all(
                    const Color(0xFFE2E8F0),
                  ),
                  thickness: WidgetStateProperty.all(10),
                  radius: const Radius.circular(999),
                  thumbVisibility: WidgetStateProperty.all(true),
                  trackVisibility: WidgetStateProperty.all(true),
                ),
                child: Scrollbar(
                  controller: _matrixHorizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  child: SingleChildScrollView(
                    controller: _matrixHorizontalController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _tableHeaderCell(
                              width: nameWidth,
                              label: 'Nhan vien',
                              align: TextAlign.left,
                            ),
                            ...trackedDates.map(
                              (date) => _tableHeaderCell(
                                width: dayWidth,
                                label: date.day.toString(),
                              ),
                            ),
                            _tableHeaderCell(
                              width: totalWidth,
                              label: 'Tong',
                            ),
                          ],
                        ),
                        ...users.map((user) {
                          final breakdownByDate = {
                            for (final day in user.dailyBreakdown) day.date: day,
                          };

                          return InkWell(
                            onTap: () => _showMonthlyDetails(user),
                            child: Row(
                              children: [
                                _tableNameCell(user, nameWidth),
                                ...trackedDates.map((date) {
                                  final key = date.toIso8601String().split('T').first;
                                  final day = breakdownByDate[key];

                                  if (day == null || day.status == 'not_recorded') {
                                    return _tableValueCell(
                                      value: '',
                                      width: dayWidth,
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    );
                                  }

                                  final backgroundColor = day.status == 'full_day'
                                      ? const Color(0xFFDCFCE7)
                                      : day.status == 'half_day'
                                          ? const Color(0xFFDBEAFE)
                                          : const Color(0xFFFEF3C7);

                                  final foregroundColor = day.status == 'full_day'
                                      ? const Color(0xFF166534)
                                      : day.status == 'half_day'
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFFB45309);

                                  final displayValue = day.workUnits > 0
                                      ? _formatWorkUnitsCell(day.workUnits)
                                      : '0.0';

                                  return _tableValueCell(
                                    value: displayValue,
                                    width: dayWidth,
                                    backgroundColor: backgroundColor,
                                    foregroundColor: foregroundColor,
                                  );
                                }),
                                _tableValueCell(
                                  value: _formatWorkUnitsCell(user.totalWorkUnits),
                                  width: totalWidth,
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  foregroundColor: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _overview == null) {
      final loadingBody = const Center(child: CircularProgressIndicator());
      return widget.embedded ? loadingBody : SafeArea(child: loadingBody);
    }

    final overview = _overview;
    final users = overview?.page.data ?? const <AdminMonthlyAttendanceUser>[];

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
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x334C1D95),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bang cong thang',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin co the theo doi tong so cong, ngay du cong va ngay can xem lai cua tung nhan vien trong thang.',
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
                        label: 'Tong nhan vien',
                        value: '${overview?.summary.totalUsers ?? 0}',
                        color: const Color(0xFFE9D5FF),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Tong cong thang',
                        value: _formatWorkUnits(
                          overview?.summary.totalWorkUnits ?? 0,
                        ),
                        color: const Color(0xFFDDD6FE),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Ngay du cong',
                        value: '${overview?.summary.fullDayTotal ?? 0}',
                        color: const Color(0xFFC4B5FD),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Chua ghi nhan',
                        value: '${overview?.summary.daysWithoutRecordTotal ?? 0}',
                        color: const Color(0xFFF5D0FE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bo loc bang cong',
            subtitle:
                'Chon thang can xem, loc theo phong ban va tim nhanh nhan vien.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickMonth,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(_formatMonthLabel(_selectedMonth)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _loadOverview(),
                        decoration: InputDecoration(
                          labelText: 'Tim nhan vien',
                          hintText: 'VD: nv001, Nguyen Van A',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => _loadOverview(),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
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
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _exporting ? null : _exportCsv,
                    icon: Icon(
                      _exporting
                          ? Icons.hourglass_top_rounded
                          : Icons.download_rounded,
                    ),
                    label: Text(
                      _exporting ? 'Dang tao file...' : 'Xuat CSV',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bang cong hien thi day du ${overview?.summary.trackedDayCount ?? 0} ngay cua thang duoc chon.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Can kiem tra lai',
              subtitle: 'Khong tai duoc bang cong thang hien tai.',
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
            title: 'Bang cong ma tran',
            subtitle:
                'Moi nhan vien la mot dong, moi ngay la mot cot, tong cong nam o cuoi hang.',
            child: users.isEmpty
                ? const Text(
                    'Khong co nhan vien phu hop voi bo loc hien tai.',
                  )
                : _matrixTable(users),
          ),
          const SizedBox(height: 16),
          _pagination(),
        ],
      ),
    );

    return widget.embedded ? body : SafeArea(child: body);
  }
}
