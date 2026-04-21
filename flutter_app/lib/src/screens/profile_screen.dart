import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/user_profile.dart';
import '../widgets/app_action_prompt.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final session = context.read<AppSession>();
      final profile = await session.profileRepository.fetchProfile();
      await _syncCurrentUser(session, profile);
      if (!mounted) return;
      _nameController.text = profile.name;
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
      setState(() {
        _profile = profile;
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

  Future<void> _syncCurrentUser(
    AppSession session,
    UserProfile profile,
  ) async {
    final currentUser = session.user;
    if (currentUser == null) {
      return;
    }

    await session.updateCurrentUser(
      currentUser.copyWith(
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        avatarPath: profile.avatarPath,
        avatarUrl: profile.avatarUrl,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final session = context.read<AppSession>();
      final result = await session.profileRepository.updateProfile(
        name: _nameController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
        phone:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
      );
      if (!mounted) return;
      final message = result.$1;
      final profile = result.$2;
      await _syncCurrentUser(session, profile);
      setState(() => _profile = profile);
      AppToast.success('Cap nhat thanh cong', message: message);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.warning('Cap nhat that bai', message: error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() => _uploadingAvatar = true);

    try {
      final session = context.read<AppSession>();
      final result = await session.profileRepository.uploadAvatar(
        filePath: pickedFile.path,
      );

      if (!mounted) {
        return;
      }

      final message = result.$1;
      final profile = result.$2;
      await _syncCurrentUser(session, profile);

      setState(() {
        _profile = profile;
      });

      AppToast.success('Cap nhat anh thanh cong', message: message);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.warning('Tai anh that bai', message: error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.error('Co loi xay ra', message: error.toString());
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  Future<void> _editBaseUrl() async {
    final session = context.read<AppSession>();
    final controller = TextEditingController(text: session.baseUrl);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doi base URL',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Neu tro sang backend khac, phien dang nhap hien tai co the khong con hop le.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://10.0.2.2:8000/api',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await session.updateBaseUrl(controller.text);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    AppToast.info(
                      'Da luu base URL',
                      message: 'Backend hien tai: ${session.baseUrl}',
                    );
                  },
                  child: const Text('Luu cau hinh'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final session = context.read<AppSession>();
    final confirmed = await AppActionPrompt.confirm(
      context: context,
      icon: Icons.logout_rounded,
      title: 'Dang xuat khoi he thong',
      message: 'Ban co chac muon ket thuc phien lam viec hien tai khong?',
      confirmLabel: 'Dang xuat',
      note: 'Du lieu da dong bo se duoc giu nguyen trong he thong.',
    );
    if (confirmed != true) return;
    await session.logout();
    AppToast.success(
      'Dang xuat thanh cong',
      message: 'Hen gap lai ban trong phien tiep theo.',
    );
  }

  Widget _metaTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _buildAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return null;
    }

    return NetworkImage(Uri.encodeFull(avatarUrl));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final user = session.user;
    final displayName = user?.name ?? '';
    final displayInitial =
        displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();
    final avatarUrl = _profile?.avatarUrl ?? user?.avatarUrl;
    final avatarProvider = _buildAvatarProvider(avatarUrl);
    if (_loading && _profile == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
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
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331E40AF),
                    blurRadius: 24,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            backgroundImage: avatarProvider,
                            child:
                                avatarProvider == null
                                    ? Text(
                                      displayInitial,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                    : null,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    _uploadingAvatar ? null : _pickAndUploadAvatar,
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: const Color(0xFFDBEAFE),
                                    ),
                                  ),
                                  child: Center(
                                    child:
                                        _uploadingAvatar
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.camera_alt_rounded,
                                              size: 18,
                                              color: Color(0xFF2563EB),
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Tai khoan',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${user?.role ?? 'Employee'} | ${user?.department ?? 'No department'}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lan dang nhap gan nhat ${formatDateTime(user?.lastLoginAt)}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _loading ? null : _loadProfile,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusBadge(
                        label:
                            _profile?.employeeCode ??
                            user?.employeeCode ??
                            '--',
                        color: const Color(0xFFDBEAFE),
                      ),
                      StatusBadge(
                        label:
                            _profile?.email?.isNotEmpty == true
                                ? 'Email da cap nhat'
                                : 'Can bo sung email',
                        color: const Color(0xFFFEF3C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nhan vao bieu tuong may anh de cap nhat anh dai dien tu thu vien anh.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Can kiem tra lai',
                subtitle: 'Khong tai duoc du lieu ho so moi nhat.',
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!)),
                    TextButton(
                      onPressed: _loadProfile,
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              title: 'Thong tin ca nhan',
              subtitle: 'Chinh sua ten, email va so dien thoai.',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue:
                          _profile?.employeeCode ?? user?.employeeCode,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Ma nhan vien',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ho va ten',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui long nhap ho va ten.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'So dien thoai',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _saveProfile,
                        child:
                            _saving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Luu thay doi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Tong quan tai khoan',
              subtitle: 'Nhanh gon de kiem tra phien dang nhap va lien he.',
              child: Column(
                children: [
                  _metaTile(
                    Icons.badge_rounded,
                    'Ma nhan vien',
                    _profile?.employeeCode ?? user?.employeeCode ?? '--',
                  ),
                  const SizedBox(height: 12),
                  _metaTile(
                    Icons.email_rounded,
                    'Email hien tai',
                    _profile?.email?.isNotEmpty == true
                        ? _profile!.email!
                        : 'Chua cap nhat',
                  ),
                  const SizedBox(height: 12),
                  _metaTile(
                    Icons.phone_rounded,
                    'So dien thoai',
                    _profile?.phone?.isNotEmpty == true
                        ? _profile!.phone!
                        : 'Chua cap nhat',
                  ),
                  const SizedBox(height: 12),
                  _metaTile(
                    Icons.image_rounded,
                    'Anh dai dien',
                    (_profile?.avatarUrl ?? user?.avatarUrl)?.isNotEmpty == true
                        ? 'Da cap nhat'
                        : 'Chua cap nhat',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Ket noi ung dung',
              subtitle: 'Quan ly backend dang duoc su dung cho app Flutter.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(session.baseUrl),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _editBaseUrl,
                          icon: const Icon(Icons.settings_ethernet_rounded),
                          label: const Text('Doi base URL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Lam moi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Phien lam viec',
              subtitle: 'Dang xuat khi can doi may chu hoac ket thuc phien.',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Dang xuat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
