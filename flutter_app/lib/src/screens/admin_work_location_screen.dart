import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../models/work_location.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';

class AdminWorkLocationScreen extends StatefulWidget {
  const AdminWorkLocationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminWorkLocationScreen> createState() => _AdminWorkLocationScreenState();
}

class _AdminWorkLocationScreenState extends State<AdminWorkLocationScreen> {
  List<WorkLocation> _locations = const [];
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
      final locations = await context.read<AppSession>()
          .adminWorkLocationRepository
          .fetchWorkLocations();

      if (!mounted) return;

      setState(() {
        _locations = locations;
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

  Future<void> _deleteLocation(WorkLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoa dia diem'),
          content: Text(
            'Ban co chac muon xoa dia diem "${location.name}" khong?',
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
      final message = await context.read<AppSession>()
          .adminWorkLocationRepository
          .deleteWorkLocation(location.id);

      if (!mounted) return;

      AppToast.success('Da xoa dia diem', message: message);
      await _bootstrap();
    } on ApiException catch (error) {
      AppToast.warning('Khong the xoa', message: error.message);
    } catch (error) {
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _openLocationSheet({WorkLocation? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final latitudeController = TextEditingController(
      text: existing == null ? '' : existing.latitude.toStringAsFixed(7),
    );
    final longitudeController = TextEditingController(
      text: existing == null ? '' : existing.longitude.toStringAsFixed(7),
    );
    final radiusController = TextEditingController(
      text: existing == null ? '50' : existing.radiusM.toString(),
    );
    final networkController = TextEditingController(
      text: existing?.allowedNetwork ?? '',
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
                          ? 'Tao dia diem cong ty'
                          : 'Chinh sua dia diem ${existing.name}',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhap thong tin dia chi cong ty, toa do GPS, ban kinh geofence va mang duoc phep de backend kiem soat cham cong.',
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
                        labelText: 'Ten dia diem',
                        hintText: 'VD: Van phong tru so',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dia chi cong ty',
                        hintText: 'VD: 123 Nguyen Van Linh, Hai Chau, Da Nang',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latitudeController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Vi do',
                              hintText: '17.4665500',
                              prefixIcon: Icon(Icons.explore_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: longitudeController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Kinh do',
                              hintText: '106.5985400',
                              prefixIcon: Icon(Icons.public_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ban kinh cho phep (m)',
                        hintText: 'VD: 50',
                        prefixIcon: Icon(Icons.radar_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: networkController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mang hop le',
                        hintText:
                            'VD: 113.161.12.141,192.168.1.0/24,2001:ee0:4bbb:a90::/64',
                        prefixIcon: Icon(Icons.wifi_tethering_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'De trong neu muon tam bo qua rule mang. Co the nhap IP don hoac CIDR, ngan cach bang dau phay.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() => isActive = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Dia diem dang hoat dong',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Chi dia diem dang hoat dong moi hien ra trong phan cham cong cua nhan vien.',
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
                                final address = addressController.text.trim();
                                final latitude = double.tryParse(
                                  latitudeController.text.trim().replaceAll(',', '.'),
                                );
                                final longitude = double.tryParse(
                                  longitudeController.text.trim().replaceAll(',', '.'),
                                );
                                final radius = int.tryParse(radiusController.text.trim());
                                final allowedNetwork = networkController.text.trim();

                                if (name.isEmpty) {
                                  AppToast.warning(
                                    'Du lieu chua hop le',
                                    message: 'Vui long nhap ten dia diem.',
                                  );
                                  return;
                                }

                                if (latitude == null || latitude < -90 || latitude > 90) {
                                  AppToast.warning(
                                    'Du lieu chua hop le',
                                    message: 'Vi do phai nam trong khoang -90 den 90.',
                                  );
                                  return;
                                }

                                if (longitude == null || longitude < -180 || longitude > 180) {
                                  AppToast.warning(
                                    'Du lieu chua hop le',
                                    message: 'Kinh do phai nam trong khoang -180 den 180.',
                                  );
                                  return;
                                }

                                if (radius == null || radius <= 0) {
                                  AppToast.warning(
                                    'Du lieu chua hop le',
                                    message: 'Ban kinh cho phep phai lon hon 0.',
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                try {
                                  final session = context.read<AppSession>();
                                  final result = existing == null
                                      ? await session.adminWorkLocationRepository
                                          .createWorkLocation(
                                            name: name,
                                            address: address.isEmpty ? null : address,
                                            latitude: latitude,
                                            longitude: longitude,
                                            radiusM: radius,
                                            allowedNetwork: allowedNetwork.isEmpty
                                                ? null
                                                : allowedNetwork,
                                            isActive: isActive,
                                          )
                                      : await session.adminWorkLocationRepository
                                          .updateWorkLocation(
                                            workLocationId: existing.id,
                                            name: name,
                                            address: address.isEmpty ? null : address,
                                            latitude: latitude,
                                            longitude: longitude,
                                            radiusM: radius,
                                            allowedNetwork: allowedNetwork.isEmpty
                                                ? null
                                                : allowedNetwork,
                                            isActive: isActive,
                                          );

                                  if (!mounted) return;

                                  Navigator.of(sheetContext).pop();
                                  AppToast.success(
                                    existing == null
                                        ? 'Da tao dia diem'
                                        : 'Da cap nhat dia diem',
                                    message: result.$1,
                                  );
                                  await _bootstrap();
                                } on ApiException catch (error) {
                                  AppToast.warning(
                                    'Luu dia diem that bai',
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
                                    ? 'Tao dia diem'
                                    : 'Luu dia diem',
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

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
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
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(WorkLocation location) {
    final active = location.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0ECFF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? const Color(0xFF93C5FD)
              : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        active ? 'Dang hoat dong' : 'Tam dung',
        style: TextStyle(
          color: active ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _locationCard(WorkLocation location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: location.isActive
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
                      location.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((location.address ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        location.address!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _statusChip(location),
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
                    child: _infoTile(
                      icon: Icons.pin_drop_outlined,
                      label: 'Toa do GPS',
                      value:
                          '${location.latitude.toStringAsFixed(7)}, ${location.longitude.toStringAsFixed(7)}',
                      iconColor: const Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _infoTile(
                      icon: Icons.radar_rounded,
                      label: 'Ban kinh cho phep',
                      value: '${location.radiusM} m',
                      iconColor: const Color(0xFF0F766E),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: _infoTile(
                      icon: Icons.wifi_tethering_rounded,
                      label: 'Mang hop le',
                      value: (location.allowedNetwork ?? '').trim().isEmpty
                          ? 'Dang bo qua rule mang cho dia diem nay.'
                          : location.allowedNetwork!.trim(),
                      iconColor: const Color(0xFF7C3AED),
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
                onPressed: () => _openLocationSheet(existing: location),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Chinh sua'),
              ),
              TextButton.icon(
                onPressed: () => _deleteLocation(location),
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
    if (_loading && _locations.isEmpty) {
      final loadingBody = const Center(child: CircularProgressIndicator());
      return widget.embedded ? loadingBody : SafeArea(child: loadingBody);
    }

    final activeCount = _locations.where((item) => item.isActive).length;
    final locationWithNetworkCount = _locations
        .where((item) => (item.allowedNetwork ?? '').trim().isNotEmpty)
        .length;

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
                colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
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
                  'Dia diem cong ty',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quan ly dia chi cong ty, geofence va mang hop le de backend kiem soat dieu kien cham cong theo GPS va mang doanh nghiep.',
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
                        label: 'Tong dia diem',
                        value: '${_locations.length}',
                        color: const Color(0xFFE0F2FE),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Dang hoat dong',
                        value: '$activeCount',
                        color: const Color(0xFFDBEAFE),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: _summaryStat(
                        label: 'Co rule mang',
                        value: '$locationWithNetworkCount',
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
            title: 'Quan ly dia diem',
            subtitle:
                'Them, sua va xoa dia diem cong ty ma khong can can thiep SQL.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moi dia diem co the gan toa do GPS, ban kinh geofence va danh sach mang hop le rieng cho tung chi nhanh.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openLocationSheet(),
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: const Text('Tao dia diem'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Admin co the cap nhat truc tiep toa do, ban kinh cho phep va rule mang hop le de nhan vien chi cham cong duoc tai dung dia diem doanh nghiep.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _openLocationSheet(),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Tao dia diem'),
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
              subtitle: 'Khong tai duoc danh sach dia diem hien tai.',
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
            title: 'Danh sach dia diem',
            subtitle:
                'Tong hop dia diem cong ty dang dung cho viec cham cong va xac thuc mang.',
            child: _locations.isEmpty
                ? const Text(
                    'Chua co dia diem cong ty nao. Hay tao dia diem dau tien cho he thong.',
                  )
                : Column(
                    children: _locations
                        .map(
                          (location) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _locationCard(location),
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
