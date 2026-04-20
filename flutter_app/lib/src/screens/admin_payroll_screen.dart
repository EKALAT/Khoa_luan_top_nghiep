import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/file_download.dart';
import '../models/admin_payroll_overview.dart';
import '../models/admin_payroll_user.dart';
import '../models/department_option.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat('#,##0.##', 'en_US');

  AdminPayrollOverview? _overview;
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
      final payrollFuture = session.adminPayrollRepository.fetchOverview(
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

  Future<void> _loadOverview({int page = 1}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = context.read<AppSession>();
      final overview = await session.adminPayrollRepository.fetchOverview(
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
            'Chuc nang xuat bang luong hien duoc toi uu de tai file truc tiep tren Flutter Web.',
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      final session = context.read<AppSession>();
      final bytes = await session.adminPayrollRepository.exportCsv(
        month: _selectedMonth,
        search: _searchController.text,
        departmentId: _departmentIdFilter,
      );

      final filename = _buildExportFilename();

      await downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'text/csv;charset=utf-8',
      );

      AppToast.success(
        'Xuat bang luong thanh cong',
        message: 'Trinh duyet dang tai file $filename',
      );
    } on ApiException catch (error) {
      AppToast.warning('Xuat bang luong that bai', message: error.message);
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

  Future<void> _editDepartmentSalary(DepartmentOption department) async {
    await _openDepartmentSheet(existing: department);
  }

  Future<void> _openDepartmentSheet({DepartmentOption? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final codeController = TextEditingController(text: existing?.code ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final salaryController = TextEditingController(
      text: (existing?.monthlySalary ?? 0).toStringAsFixed(0),
    );
    bool isActive = existing?.isActive ?? true;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Tao phong ban moi'
                        : 'Chinh sua phong ban ${existing.name}',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    existing == null
                        ? 'Nhap thong tin phong ban va muc luong co dinh theo thang.'
                        : 'Cap nhat ten, ma, mo ta, trang thai va luong co dinh cua phong ban nay.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: existing == null,
                    decoration: const InputDecoration(
                      labelText: 'Ten phong ban',
                      hintText: 'VD: Ke toan',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Ma phong ban',
                      hintText: 'VD: accounting',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mo ta',
                      hintText: 'Mo ta ngan cho phong ban',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: salaryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Luong thang',
                      hintText: 'VD: 10000000',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: isActive,
                    onChanged: (value) {
                      setModalState(() => isActive = value);
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Phong ban dang hoat dong',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Phong ban ngung hoat dong van duoc luu de theo doi lich su.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final code = codeController.text.trim();
                              final parsed = double.tryParse(
                                salaryController.text.trim().replaceAll(',', ''),
                              );

                              if (name.isEmpty || code.isEmpty) {
                                AppToast.warning(
                                  'Du lieu chua hop le',
                                  message:
                                      'Vui long nhap ten phong ban va ma phong ban.',
                                );
                                return;
                              }

                              if (parsed == null || parsed < 0) {
                                AppToast.warning(
                                  'Du lieu chua hop le',
                                  message:
                                      'Vui long nhap luong phong ban bang so va lon hon hoac bang 0.',
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final session = context.read<AppSession>();
                                final result = existing == null
                                    ? await session.adminDepartmentRepository
                                        .createDepartment(
                                          name: name,
                                          code: code,
                                          description:
                                              descriptionController.text.trim().isEmpty
                                              ? null
                                              : descriptionController.text.trim(),
                                          monthlySalary: parsed,
                                          isActive: isActive,
                                        )
                                    : await session.adminDepartmentRepository
                                        .updateDepartment(
                                          departmentId: existing.id,
                                          name: name,
                                          code: code,
                                          description:
                                              descriptionController.text.trim().isEmpty
                                              ? null
                                              : descriptionController.text.trim(),
                                          monthlySalary: parsed,
                                          isActive: isActive,
                                        );
                                final (message, updatedDepartment) = result;

                                if (!mounted) return;

                                setState(() {
                                  final exists = _departments.any(
                                    (item) => item.id == updatedDepartment.id,
                                  );
                                  final next = exists
                                      ? _departments
                                          .map(
                                            (item) =>
                                                item.id == updatedDepartment.id
                                                ? updatedDepartment
                                                : item,
                                          )
                                          .toList(growable: false)
                                      : [
                                          ..._departments,
                                          updatedDepartment,
                                        ];

                                  next.sort(
                                    (left, right) => left.name.toLowerCase().compareTo(
                                      right.name.toLowerCase(),
                                    ),
                                  );
                                  _departments = next;
                                });

                                Navigator.of(sheetContext).pop();
                                AppToast.success(
                                  existing == null
                                      ? 'Da tao phong ban'
                                      : 'Da cap nhat phong ban',
                                  message: message,
                                );
                                await _loadOverview(
                                  page: _overview?.page.currentPage ?? 1,
                                );
                              } on ApiException catch (error) {
                                AppToast.warning(
                                  'Cap nhat that bai',
                                  message: error.message,
                                );
                              } catch (error) {
                                AppToast.error(
                                  'Co loi xay ra',
                                  message: error.toString(),
                                );
                              } finally {
                                if (context.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              existing == null
                                  ? 'Tao phong ban'
                                  : 'Luu phong ban',
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatMonthLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '$month/${value.year}';
  }

  String _buildExportFilename() {
    final year = _selectedMonth.year.toString().padLeft(4, '0');
    final month = _selectedMonth.month.toString().padLeft(2, '0');
    final departmentPart = _selectedDepartmentFilenamePart();
    return 'Bang_luong_${departmentPart}_${year}_$month.csv';
  }

  String _selectedDepartmentFilenamePart() {
    if (_departmentIdFilter == null) {
      return 'tat_ca';
    }

    DepartmentOption? department;
    for (final item in _departments) {
      if (item.id == _departmentIdFilter) {
        department = item;
        break;
      }
    }

    if (department == null) {
      return 'phong_ban_$_departmentIdFilter';
    }

    return _normalizeFilenamePart(department.name);
  }

  String _normalizeFilenamePart(String value) {
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
      'À': 'A',
      'Á': 'A',
      'Ạ': 'A',
      'Ả': 'A',
      'Ã': 'A',
      'Â': 'A',
      'Ầ': 'A',
      'Ấ': 'A',
      'Ậ': 'A',
      'Ẩ': 'A',
      'Ẫ': 'A',
      'Ă': 'A',
      'Ằ': 'A',
      'Ắ': 'A',
      'Ặ': 'A',
      'Ẳ': 'A',
      'Ẵ': 'A',
      'È': 'E',
      'É': 'E',
      'Ẹ': 'E',
      'Ẻ': 'E',
      'Ẽ': 'E',
      'Ê': 'E',
      'Ề': 'E',
      'Ế': 'E',
      'Ệ': 'E',
      'Ể': 'E',
      'Ễ': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Ị': 'I',
      'Ỉ': 'I',
      'Ĩ': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ọ': 'O',
      'Ỏ': 'O',
      'Õ': 'O',
      'Ô': 'O',
      'Ồ': 'O',
      'Ố': 'O',
      'Ộ': 'O',
      'Ổ': 'O',
      'Ỗ': 'O',
      'Ơ': 'O',
      'Ờ': 'O',
      'Ớ': 'O',
      'Ợ': 'O',
      'Ở': 'O',
      'Ỡ': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Ụ': 'U',
      'Ủ': 'U',
      'Ũ': 'U',
      'Ư': 'U',
      'Ừ': 'U',
      'Ứ': 'U',
      'Ự': 'U',
      'Ử': 'U',
      'Ữ': 'U',
      'Ỳ': 'Y',
      'Ý': 'Y',
      'Ỵ': 'Y',
      'Ỷ': 'Y',
      'Ỹ': 'Y',
      'Đ': 'D',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }

    final normalized = buffer.toString().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final trimmed = normalized.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');

    return trimmed.isEmpty ? 'phong_ban' : trimmed;
  }

  String _formatWorkUnits(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatMoney(double value) => _currencyFormat.format(value);

  Widget _summaryStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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

  Widget _departmentSalaryCard(DepartmentOption department) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      department.code,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((department.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        department.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _editDepartmentSalary(department),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Sua luong',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatMoney(department.monthlySalary),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                department.isActive ? 'Dang hoat dong' : 'Tam ngung',
                style: TextStyle(
                  color: department.isActive
                      ? const Color(0xFF166534)
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Luong co dinh / thang',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DepartmentOption> _activeDepartmentsForFilter() {
    final items = _departments
        .where((department) => department.isActive)
        .toList(growable: false);

    if (_departmentIdFilter == null) {
      return items;
    }

    final selectedExists = items.any(
      (department) => department.id == _departmentIdFilter,
    );

    if (selectedExists) {
      return items;
    }

    final selected = _departments.where(
      (department) => department.id == _departmentIdFilter,
    );

    return [
      ...items,
      ...selected,
    ];
  }

  Widget _departmentManagementHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Admin co the tao them phong ban moi, cap nhat luong co dinh va dieu chinh trang thai ngay trong man nay.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () => _openDepartmentSheet(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tao phong ban'),
        ),
      ],
    );
  }

  Widget _payrollCard(AdminPayrollUser user) {
    final avatarProvider =
        (user.avatarUrl ?? '').isEmpty ? null : NetworkImage(user.avatarUrl!);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
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
                      '${user.employeeCode} | ${user.department ?? 'Chua gan phong ban'}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip('Tong cong', _formatWorkUnits(user.totalWorkUnits)),
              _infoChip('Cong tinh luong', _formatWorkUnits(user.paidWorkUnits)),
              _infoChip('Luong phong ban', _formatMoney(user.monthlySalary)),
              _infoChip('Luong / cong', _formatMoney(user.unitSalary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFE0EAFF)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Luong thuc nhan',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(user.salaryAmount),
                  style: const TextStyle(
                    color: Color(0xFF312E81),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
                colors: [Color(0xFF9A3412), Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33EA580C),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bang luong thang',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Luong duoc tinh tu dong theo luong co dinh cua phong ban va tong cong hop le trong thang.',
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
                      width: 170,
                      child: _summaryStat(
                        label: 'Tong nhan vien',
                        value: '${overview?.summary.totalUsers ?? 0}',
                        color: const Color(0xFFFFEDD5),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Tong cong',
                        value: _formatWorkUnits(
                          overview?.summary.totalWorkUnits ?? 0,
                        ),
                        color: const Color(0xFFFED7AA),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Tong luong phong ban',
                        value: _formatMoney(
                          overview?.summary.totalMonthlySalary ?? 0,
                        ),
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Luong thuc nhan',
                        value: _formatMoney(
                          overview?.summary.totalSalaryAmount ?? 0,
                        ),
                        color: const Color(0xFFFFF7ED),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Luong phong ban',
            subtitle:
                'Admin cap nhat luong co dinh theo thang cho tung phong ban. Phan bonus hoac tang luong se duoc xu ly ngoai he thong.',
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin co the tao them phong ban moi, cap nhat luong co dinh va dieu chinh trang thai ngay trong man nay.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _openDepartmentSheet(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tao phong ban'),
                          ),
                        ],
                      );
                    }

                    return _departmentManagementHeader();
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 1080
                        ? (constraints.maxWidth - 24) / 4
                        : constraints.maxWidth >= 760
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _departments
                          .map(
                            (department) => SizedBox(
                              width: cardWidth,
                              child: _departmentSalaryCard(department),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bo loc bang luong',
            subtitle:
                'Chon thang can tinh luong, loc theo phong ban va tim nhanh nhan vien.',
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    if (!isWide) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickMonth,
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(_formatMonthLabel(_selectedMonth)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
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
                        ],
                      );
                    }

                    return Row(
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
                    );
                  },
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
                    ..._activeDepartmentsForFilter().map(
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quy tac tinh luong: du 25 cong tro len se nhan du luong phong ban, duoi 25 cong se tinh theo cong thuc te.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
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
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Quy tac tinh luong: du 25 cong tro len se nhan du luong phong ban, duoi 25 cong se tinh theo cong thuc te.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
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
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Can kiem tra lai',
              subtitle: 'Khong tai duoc bang luong thang hien tai.',
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
                'Muc luong duoc tinh tu dong tu tong cong hop le va luong co dinh cua phong ban.',
            child: payrollUsers.isEmpty
                ? const Text(
                    'Khong co nhan vien phu hop voi bo loc hien tai.',
                  )
                : Column(
                    children: payrollUsers
                        .map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _payrollCard(user),
                          ),
                        )
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
