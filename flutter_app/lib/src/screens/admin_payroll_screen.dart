import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/admin_department_salary.dart';
import '../models/admin_payroll_overview.dart';
import '../models/admin_payroll_user.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  final _searchController = TextEditingController();

  AdminPayrollOverview? _overview;
  List<AdminDepartmentSalary> _departments = const [];
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
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = context.read<AppSession>();
      final departmentsFuture =
          session.adminPayrollRepository.fetchDepartmentSalaries();
      final payrollFuture = session.adminPayrollRepository.fetchMonthlyPayroll(
        month: _selectedMonth,
      );

      final departments = await departmentsFuture;
      final overview = await payrollFuture;

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

  Future<void> _loadPayroll({int page = 1}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = context.read<AppSession>();
      final overview = await session.adminPayrollRepository.fetchMonthlyPayroll(
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
    await _loadPayroll();
  }

  Future<void> _exportPayroll() async {
    if (_exporting) {
      return;
    }

    setState(() => _exporting = true);

    try {
      final session = context.read<AppSession>();
      final bytes = await session.adminPayrollRepository.exportMonthlyPayrollCsv(
        month: _selectedMonth,
        search: _searchController.text,
        departmentId: _departmentIdFilter,
      );

      final directory = await _resolveExportDirectory();
      await directory.create(recursive: true);

      final fileName =
          'bang_luong_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}.csv';
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);

      AppToast.success(
        'Xuat bang luong thanh cong',
        message: 'Tap tin CSV da duoc luu tai ${file.path}',
      );
    } on ApiException catch (error) {
      AppToast.warning('Xuat bang luong that bai', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    if (!Platform.isAndroid) {
      return getApplicationDocumentsDirectory();
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return Directory(
        '${externalDir.path}${Platform.pathSeparator}payroll_exports',
      );
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(
      '${documentsDir.path}${Platform.pathSeparator}payroll_exports',
    );
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

  Color _salaryStateColor(bool configured) {
    return configured ? const Color(0xFF15803D) : const Color(0xFFB45309);
  }

  String _salaryStateLabel(AdminPayrollUser user) {
    if (!user.hasSalaryConfigured) {
      return 'Chua cau hinh';
    }

    if (user.payableWorkUnits >= user.standardWorkDays) {
      return 'Du luong';
    }

    return 'Tinh theo cong';
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

  Future<void> _showDepartmentForm({AdminDepartmentSalary? initial}) async {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final codeController = TextEditingController(text: initial?.code ?? '');
    final descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    final salaryController = TextEditingController(
      text: initial == null ? '' : initial.monthlySalary.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    var isActive = initial?.isActive ?? true;
    var submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              final monthlySalary =
                  double.tryParse(salaryController.text.trim()) ?? 0;

              setSheetState(() => submitting = true);

              try {
                final session = context.read<AppSession>();
                final result = initial == null
                    ? await session.adminPayrollRepository.createDepartmentSalary(
                        name: nameController.text.trim(),
                        code: codeController.text.trim().toUpperCase(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        monthlySalary: monthlySalary,
                        isActive: isActive,
                      )
                    : await session.adminPayrollRepository.updateDepartmentSalary(
                        initial.id,
                        name: nameController.text.trim(),
                        code: codeController.text.trim().toUpperCase(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        monthlySalary: monthlySalary,
                        isActive: isActive,
                      );

                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                AppToast.success(
                  initial == null ? 'Tao phong ban thanh cong' : 'Cap nhat thanh cong',
                  message: result.$1,
                );
                await _bootstrap();
              } on ApiException catch (error) {
                AppToast.warning(
                  initial == null ? 'Tao phong ban that bai' : 'Cap nhat that bai',
                  message: error.message,
                );
              } catch (error) {
                AppToast.error('Co loi xay ra', message: error.toString());
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() => submitting = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          initial == null ? 'Them phong ban va luong' : 'Cap nhat phong ban',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Luong thang se duoc ap cho tat ca nhan vien thuoc phong ban nay theo quy tac 25 cong.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ten phong ban',
                            hintText: 'VD: IT, Ke toan',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui long nhap ten phong ban.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Ma phong ban',
                            hintText: 'VD: IT, HR, KT',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Vui long nhap ma phong ban.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Mo ta',
                            hintText: 'Mo ta ngan cho phong ban nay',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: salaryController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Luong thang mac dinh',
                            hintText: 'VD: 9000000',
                          ),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            if (raw.isEmpty) {
                              return 'Vui long nhap luong thang.';
                            }

                            final parsed = double.tryParse(raw);
                            if (parsed == null || parsed < 0) {
                              return 'Luong thang khong hop le.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          value: isActive,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Kich hoat phong ban'),
                          subtitle: const Text(
                            'Tat phong ban chi khi khong con su dung cho quy trinh cham cong.',
                          ),
                          onChanged: submitting
                              ? null
                              : (value) => setSheetState(() => isActive = value),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: submitting ? null : submit,
                            icon: Icon(
                              submitting
                                  ? Icons.hourglass_top_rounded
                                  : initial == null
                                      ? Icons.add_business_rounded
                                      : Icons.save_rounded,
                            ),
                            label: Text(
                              submitting
                                  ? 'Dang xu ly...'
                                  : initial == null
                                      ? 'Tao phong ban'
                                      : 'Luu thay doi',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteDepartment(AdminDepartmentSalary department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoa phong ban?'),
          content: Text(
            'Ban muon xoa phong ban ${department.name}. Neu phong ban con nhan vien, he thong se tu choi thao tac nay.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final session = context.read<AppSession>();
      final message = await session.adminPayrollRepository.deleteDepartmentSalary(
        department.id,
      );

      AppToast.success('Xoa phong ban thanh cong', message: message);
      await _bootstrap();
    } on ApiException catch (error) {
      AppToast.warning('Xoa phong ban that bai', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _showPayrollDetails(AdminPayrollUser user) async {
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
                  '${user.name} - Chi tiet luong',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.employeeCode} | ${user.department ?? 'Chua co phong ban'}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: 'Cong thuc te ${_formatWorkUnits(user.totalWorkUnits)}',
                      color: const Color(0xFF1D4ED8),
                    ),
                    StatusBadge(
                      label: 'Cong tinh luong ${_formatWorkUnits(user.payableWorkUnits)}',
                      color: const Color(0xFF0F766E),
                    ),
                    StatusBadge(
                      label: _salaryStateLabel(user),
                      color: _salaryStateColor(user.hasSalaryConfigured),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Luong thang phong ban: ${formatCurrency(user.monthlySalary)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Luong / cong: ${formatCurrency(user.unitSalary, decimalDigits: 2)}',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Luong thuc nhan: ${formatCurrency(user.netSalary)}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
                              'Cong ngay: ${_formatWorkUnits(day.workUnits)} | Moc hop le: ${day.validRecordCount}',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (day.moments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: day.moments
                                    .map(
                                      (moment) => StatusBadge(
                                        label:
                                            '${attendanceTypeLabel(moment.checkType)} ${formatTime(moment.checkTime)}',
                                        color: const Color(0xFF334155),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
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

  Widget _departmentCard(AdminDepartmentSalary department) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ma: ${department.code}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showDepartmentForm(initial: department);
                    return;
                  }

                  _confirmDeleteDepartment(department);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Cap nhat'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xoa'),
                  ),
                ],
              ),
            ],
          ),
          if ((department.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              department.description!,
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: formatCurrency(department.monthlySalary),
                color: const Color(0xFF7C3AED),
              ),
              StatusBadge(
                label: '${department.userCount} nhan vien',
                color: const Color(0xFF0F766E),
              ),
              StatusBadge(
                label: department.isActive ? 'Dang hoat dong' : 'Tam dung',
                color: department.isActive
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB45309),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _payrollCard(AdminPayrollUser user) {
    final avatarProvider =
        (user.avatarUrl ?? '').isEmpty ? null : NetworkImage(user.avatarUrl!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: user.hasSalaryConfigured
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFFDE68A),
        ),
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
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.employeeCode} | ${user.department ?? 'Chua co phong ban'}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: _salaryStateLabel(user),
                          color: _salaryStateColor(user.hasSalaryConfigured),
                        ),
                        StatusBadge(
                          label: 'Cong ${_formatWorkUnits(user.totalWorkUnits)}',
                          color: const Color(0xFF1D4ED8),
                        ),
                        StatusBadge(
                          label: 'Tinh luong ${_formatWorkUnits(user.payableWorkUnits)}',
                          color: const Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPayrollDetails(user),
                icon: const Icon(Icons.visibility_rounded),
                tooltip: 'Chi tiet',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricTile(
                label: 'Luong thang',
                value: formatCurrency(user.monthlySalary),
                color: const Color(0xFFF5F3FF),
              ),
              _metricTile(
                label: 'Luong / cong',
                value: formatCurrency(user.unitSalary, decimalDigits: 2),
                color: const Color(0xFFEEF2FF),
              ),
              _metricTile(
                label: 'Luong thuc nhan',
                value: formatCurrency(user.netSalary),
                color: const Color(0xFFECFDF5),
              ),
            ],
          ),
          if (!user.hasSalaryConfigured) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Phong ban nay chua co luong mac dinh, vi vay bang luong hien tai dang la 0.',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
                ? () => _loadPayroll(page: page.currentPage - 1)
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
                ? () => _loadPayroll(page: page.currentPage + 1)
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
    final payrollUsers = overview?.page.data ?? const <AdminPayrollUser>[];

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
                colors: [Color(0xFF7C2D12), Color(0xFF9A3412)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x339A3412),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bang luong theo cong',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Luong duoc tinh theo muc luong phong ban va tong cong thang. Du 25 cong nhan du luong, duoi 25 cong se tinh theo cong thuc te.',
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
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Tong cong',
                        value: _formatWorkUnits(
                          overview?.summary.totalWorkUnits ?? 0,
                        ),
                        color: const Color(0xFFFED7AA),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _summaryStat(
                        label: 'Du luong',
                        value: '${overview?.summary.fullSalaryEmployeeCount ?? 0}',
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Tong quy luong',
                        value: formatCurrency(
                          overview?.summary.totalNetSalary ?? 0,
                        ),
                        color: const Color(0xFFFFEDD5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Cau hinh luong phong ban',
            subtitle:
                'Admin co the CRUD phong ban va luong mac dinh de he thong tinh bang luong tu dong.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _showDepartmentForm(),
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Them phong ban'),
                  ),
                ),
                const SizedBox(height: 14),
                if (_departments.isEmpty)
                  const Text('Chua co phong ban nao de cau hinh luong.')
                else
                  Column(
                    children: _departments
                        .map(_departmentCard)
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bo loc bang luong',
            subtitle:
                'Chon thang can tinh luong, loc theo phong ban va xuat file CSV mo duoc bang Excel.',
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
                        onSubmitted: (_) => _loadPayroll(),
                        decoration: InputDecoration(
                          labelText: 'Tim nhan vien',
                          hintText: 'VD: nv001, Nguyen Van A',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => _loadPayroll(),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _departmentIdFilter,
                        decoration: const InputDecoration(
                          labelText: 'Phong ban',
                        ),
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
                          _loadPayroll();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _exporting ? null : _exportPayroll,
                        icon: Icon(
                          _exporting
                              ? Icons.hourglass_top_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(
                          _exporting ? 'Dang tao file...' : 'Xuat Excel',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quy tac: 25 cong nhan du luong. Muc luong thang hien lay truc tiep tu phong ban.',
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
              subtitle: 'Khong tai duoc bang luong hien tai.',
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
            title: 'Danh sach bang luong',
            subtitle:
                'Bang luong duoc tinh tu dong theo tong cong thang va muc luong phong ban.',
            child: payrollUsers.isEmpty
                ? const Text(
                    'Khong co nhan vien phu hop voi bo loc hien tai.',
                  )
                : Column(
                    children: payrollUsers
                        .map(_payrollCard)
                        .toList(growable: false),
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
