import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../models/shift_rule.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';

class AdminShiftRuleScreen extends StatefulWidget {
  const AdminShiftRuleScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminShiftRuleScreen> createState() => _AdminShiftRuleScreenState();
}

class _AdminShiftRuleScreenState extends State<AdminShiftRuleScreen> {
  static const Map<String, String> _defaultTimes = <String, String>{
    'morning_check_in_start': '07:30:00',
    'morning_check_in_end': '08:30:00',
    'morning_check_out_start': '11:00:00',
    'morning_check_out_end': '11:45:00',
    'afternoon_check_in_start': '13:00:00',
    'afternoon_check_in_end': '14:00:00',
    'afternoon_check_out_start': '16:30:00',
    'afternoon_check_out_end': '17:30:00',
  };

  List<ShiftRule> _rules = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final rules = await context.read<AppSession>().adminShiftRuleRepository
          .fetchShiftRules();

      if (!mounted) return;

      setState(() {
        _rules = rules;
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

  Future<void> _activateRule(ShiftRule rule) async {
    try {
      final session = context.read<AppSession>();
      final (message, _) = await session.adminShiftRuleRepository.updateShiftRule(
        shiftRuleId: rule.id,
        isActive: true,
      );

      if (!mounted) return;

      AppToast.success('Da kich hoat khung gio', message: message);
      await _bootstrap();
    } on ApiException catch (error) {
      AppToast.warning('Khong the kich hoat', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _deleteRule(ShiftRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoa khung gio'),
          content: Text(
            'Ban co chac muon xoa khung gio "${rule.name}" khong?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final message = await context.read<AppSession>().adminShiftRuleRepository
          .deleteShiftRule(rule.id);

      if (!mounted) return;

      AppToast.success('Da xoa khung gio', message: message);
      await _bootstrap();
    } on ApiException catch (error) {
      AppToast.warning('Khong the xoa', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _openShiftRuleSheet({ShiftRule? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final timeValues = <String, String>{
      ..._defaultTimes,
      if (existing != null) ...<String, String>{
        'morning_check_in_start': existing.morningCheckInStart,
        'morning_check_in_end': existing.morningCheckInEnd,
        'morning_check_out_start': existing.morningCheckOutStart,
        'morning_check_out_end': existing.morningCheckOutEnd,
        'afternoon_check_in_start': existing.afternoonCheckInStart,
        'afternoon_check_in_end': existing.afternoonCheckInEnd,
        'afternoon_check_out_start': existing.afternoonCheckOutStart,
        'afternoon_check_out_end': existing.afternoonCheckOutEnd,
      },
    };
    bool isActive = existing?.isActive ?? (_rules.every((rule) => !rule.isActive));
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickTime(String key) async {
              final picked = await showTimePicker(
                context: sheetContext,
                initialTime: _parseTimeOfDay(timeValues[key]!),
              );

              if (picked == null) {
                return;
              }

              setModalState(() {
                timeValues[key] = _formatApiTime(picked);
              });
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Tao khung gio moi'
                          : 'Chinh sua khung gio ${existing.name}',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Moi khung gio gom 4 moc cham cong. Khi bat mot khung gio, he thong se tu dong dung khung gio do de xac dinh check-in va check-out.',
                      style: Theme.of(sheetContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: const Color(0xFF64748B),
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      autofocus: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Ten khung gio',
                        hintText: 'VD: Ca hanh chinh',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _timeSection(
                      title: 'Buoi sang',
                      items: [
                        _TimeFieldConfig(
                          keyName: 'morning_check_in_start',
                          label: 'Bat dau vao ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'morning_check_in_end',
                          label: 'Ket thuc vao ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'morning_check_out_start',
                          label: 'Bat dau ra ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'morning_check_out_end',
                          label: 'Ket thuc ra ca',
                        ),
                      ],
                      values: timeValues,
                      onTap: pickTime,
                    ),
                    const SizedBox(height: 16),
                    _timeSection(
                      title: 'Buoi chieu',
                      items: [
                        _TimeFieldConfig(
                          keyName: 'afternoon_check_in_start',
                          label: 'Bat dau vao ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'afternoon_check_in_end',
                          label: 'Ket thuc vao ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'afternoon_check_out_start',
                          label: 'Bat dau ra ca',
                        ),
                        _TimeFieldConfig(
                          keyName: 'afternoon_check_out_end',
                          label: 'Ket thuc ra ca',
                        ),
                      ],
                      values: timeValues,
                      onTap: pickTime,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() => isActive = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Dang ap dung',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Neu bat khung gio nay, cac khung gio khac se tu dong ve trang thai tat.',
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
                                final validation = _validateTimeRanges(timeValues);

                                if (name.isEmpty) {
                                  AppToast.warning(
                                    'Du lieu chua hop le',
                                    message: 'Vui long nhap ten khung gio.',
                                  );
                                  return;
                                }

                                if (validation != null) {
                                  AppToast.warning(
                                    'Khung gio chua hop le',
                                    message: validation,
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                try {
                                  final session = context.read<AppSession>();
                                  final result = existing == null
                                      ? await session.adminShiftRuleRepository
                                          .createShiftRule(
                                            name: name,
                                            morningCheckInStart:
                                                timeValues['morning_check_in_start']!,
                                            morningCheckInEnd:
                                                timeValues['morning_check_in_end']!,
                                            morningCheckOutStart:
                                                timeValues['morning_check_out_start']!,
                                            morningCheckOutEnd:
                                                timeValues['morning_check_out_end']!,
                                            afternoonCheckInStart:
                                                timeValues['afternoon_check_in_start']!,
                                            afternoonCheckInEnd:
                                                timeValues['afternoon_check_in_end']!,
                                            afternoonCheckOutStart:
                                                timeValues['afternoon_check_out_start']!,
                                            afternoonCheckOutEnd:
                                                timeValues['afternoon_check_out_end']!,
                                            isActive: isActive,
                                          )
                                      : await session.adminShiftRuleRepository
                                          .updateShiftRule(
                                            shiftRuleId: existing.id,
                                            name: name,
                                            morningCheckInStart:
                                                timeValues['morning_check_in_start'],
                                            morningCheckInEnd:
                                                timeValues['morning_check_in_end'],
                                            morningCheckOutStart:
                                                timeValues['morning_check_out_start'],
                                            morningCheckOutEnd:
                                                timeValues['morning_check_out_end'],
                                            afternoonCheckInStart:
                                                timeValues['afternoon_check_in_start'],
                                            afternoonCheckInEnd:
                                                timeValues['afternoon_check_in_end'],
                                            afternoonCheckOutStart:
                                                timeValues['afternoon_check_out_start'],
                                            afternoonCheckOutEnd:
                                                timeValues['afternoon_check_out_end'],
                                            isActive: isActive,
                                          );

                                  if (!mounted) return;

                                  Navigator.of(sheetContext).pop();
                                  AppToast.success(
                                    existing == null
                                        ? 'Da tao khung gio'
                                        : 'Da cap nhat khung gio',
                                    message: result.$1,
                                  );
                                  await _bootstrap();
                                } on ApiException catch (error) {
                                  AppToast.warning(
                                    'Luu khung gio that bai',
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
                                    ? 'Tao khung gio'
                                    : 'Luu khung gio',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _validateTimeRanges(Map<String, String> values) {
    final ranges = [
      (
        title: 'vao ca sang',
        start: values['morning_check_in_start']!,
        end: values['morning_check_in_end']!,
      ),
      (
        title: 'ra ca sang',
        start: values['morning_check_out_start']!,
        end: values['morning_check_out_end']!,
      ),
      (
        title: 'vao ca chieu',
        start: values['afternoon_check_in_start']!,
        end: values['afternoon_check_in_end']!,
      ),
      (
        title: 'ra ca chieu',
        start: values['afternoon_check_out_start']!,
        end: values['afternoon_check_out_end']!,
      ),
    ];

    for (final range in ranges) {
      if (_toMinutes(range.start) >= _toMinutes(range.end)) {
        return 'Khung ${range.title} can co gio bat dau som hon gio ket thuc.';
      }
    }

    return null;
  }

  int _toMinutes(String value) {
    final segments = value.split(':');
    if (segments.length < 2) {
      return 0;
    }

    final hour = int.tryParse(segments[0]) ?? 0;
    final minute = int.tryParse(segments[1]) ?? 0;
    return (hour * 60) + minute;
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final segments = value.split(':');
    final hour = int.tryParse(segments[0]) ?? 0;
    final minute = int.tryParse(segments[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatApiTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _displayTime(String value) {
    final segments = value.split(':');
    if (segments.length < 2) {
      return value;
    }

    return '${segments[0].padLeft(2, '0')}:${segments[1].padLeft(2, '0')}';
  }

  Widget _timeSection({
    required String title,
    required List<_TimeFieldConfig> items,
    required Map<String, String> values,
    required Future<void> Function(String key) onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        child: OutlinedButton.icon(
                          onPressed: () => onTap(item.keyName),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: Color(0xFFD6E0EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.access_time_rounded),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayTime(values[item.keyName]!),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

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

  Widget _statusChip({
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _timeWindowTile({
    required IconData icon,
    required String title,
    required String start,
    required String end,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_displayTime(start)} - ${_displayTime(end)}',
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
    );
  }

  Widget _ruleCard(ShiftRule rule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: rule.isActive
              ? const Color(0xFF93C5FD)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
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
                      rule.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rule.isActive
                          ? 'Khung gio nay dang duoc he thong su dung de phan loai check-in va check-out.'
                          : 'Khung gio dang tam ngung. Admin co the chinh sua va kich hoat lai bat cu luc nao.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _statusChip(
                label: rule.isActive ? 'Dang ap dung' : 'Tam dung',
                color: rule.isActive
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF64748B),
                background: rule.isActive
                    ? const Color(0xFFE0ECFF)
                    : const Color(0xFFF1F5F9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 860
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _timeWindowTile(
                      icon: Icons.login_rounded,
                      title: 'Vao ca sang',
                      start: rule.morningCheckInStart,
                      end: rule.morningCheckInEnd,
                      iconColor: const Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _timeWindowTile(
                      icon: Icons.logout_rounded,
                      title: 'Ra ca sang',
                      start: rule.morningCheckOutStart,
                      end: rule.morningCheckOutEnd,
                      iconColor: const Color(0xFF0F766E),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _timeWindowTile(
                      icon: Icons.login_rounded,
                      title: 'Vao ca chieu',
                      start: rule.afternoonCheckInStart,
                      end: rule.afternoonCheckInEnd,
                      iconColor: const Color(0xFF7C3AED),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _timeWindowTile(
                      icon: Icons.logout_rounded,
                      title: 'Ra ca chieu',
                      start: rule.afternoonCheckOutStart,
                      end: rule.afternoonCheckOutEnd,
                      iconColor: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openShiftRuleSheet(existing: rule),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Chinh sua'),
              ),
              if (!rule.isActive)
                FilledButton.icon(
                  onPressed: () => _activateRule(rule),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Kich hoat'),
                ),
              TextButton.icon(
                onPressed: () => _deleteRule(rule),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xoa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _rules.isEmpty) {
      final loadingBody = const Center(child: CircularProgressIndicator());
      return widget.embedded ? loadingBody : SafeArea(child: loadingBody);
    }

    final activeCount = _rules.where((rule) => rule.isActive).length;

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
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x331D4ED8),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khung gio cham cong',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin co the tao va chinh sua khung gio check-in, check-out ma khong can mo SQL. He thong chi su dung mot khung gio dang ap dung tai mot thoi diem.',
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
                        label: 'Tong khung gio',
                        value: '${_rules.length}',
                        color: const Color(0xFFDCEBFF),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Dang ap dung',
                        value: '$activeCount',
                        color: const Color(0xFFDBEAFE),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Tam dung',
                        value: '${_rules.length - activeCount}',
                        color: const Color(0xFFBFDBFE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Quan ly khung gio',
            subtitle:
                'Moi khung gio gom 4 moc: vao ca sang, ra ca sang, vao ca chieu va ra ca chieu.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khi admin kich hoat mot khung gio, cac khung gio khac se tu dong tat de tranh xung dot logic cham cong.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openShiftRuleSheet(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tao khung gio'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Admin co the chinh sua khung gio linh hoat ngay trong he thong. Ca duoc bat se la ca duy nhat duoc AttendanceController ap dung.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _openShiftRuleSheet(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tao khung gio'),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Can kiem tra lai',
              subtitle: 'Khong tai duoc danh sach khung gio hien tai.',
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
            title: 'Danh sach khung gio',
            subtitle:
                'Quan ly tap trung cac moc cham cong de backend xac dinh dung check-in, check-out theo ngay.',
            child: _rules.isEmpty
                ? const Text(
                    'Chua co khung gio nao. Hay tao khung gio dau tien cho he thong.',
                  )
                : Column(
                    children: _rules
                        .map(
                          (rule) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ruleCard(rule),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );

    return widget.embedded ? body : SafeArea(child: body);
  }
}

class _TimeFieldConfig {
  const _TimeFieldConfig({
    required this.keyName,
    required this.label,
  });

  final String keyName;
  final String label;
}
