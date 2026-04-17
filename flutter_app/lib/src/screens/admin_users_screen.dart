import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../core/network/api_exception.dart';
import '../core/utils/display_utils.dart';
import '../models/admin_user.dart';
import '../models/department_option.dart';
import '../models/paginated_response.dart';
import '../models/role_option.dart';
import '../widgets/app_toast.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();

  PaginatedResponse<AdminUser>? _usersPage;
  List<RoleOption> _roles = const [];
  List<DepartmentOption> _departments = const [];
  bool _loading = true;
  String? _errorMessage;
  String? _roleCodeFilter;
  bool? _activeFilter;

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
      final rolesFuture = session.metaRepository.fetchRoles();
      final departmentsFuture = session.metaRepository.fetchDepartments();
      final usersFuture = session.adminUserRepository.fetchUsers();

      final roles = await rolesFuture;
      final departments = await departmentsFuture;
      final usersPage = await usersFuture;

      if (!mounted) return;

      setState(() {
        _roles = roles;
        _departments = departments;
        _usersPage = usersPage;
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

  Future<void> _loadUsers({int page = 1, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final session = context.read<AppSession>();
      final usersPage = await session.adminUserRepository.fetchUsers(
        page: page,
        search: _searchController.text,
        roleCode: _roleCodeFilter,
        isActive: _activeFilter,
      );

      if (!mounted) return;

      setState(() {
        _usersPage = usersPage;
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

  Future<void> _toggleUserStatus(AdminUser user) async {
    try {
      final session = context.read<AppSession>();
      final result = await session.adminUserRepository.updateUser(
        user.id,
        isActive: !user.isActive,
      );

      if (!mounted) return;

      AppToast.success('Cap nhat thanh cong', message: result.$1);
      await _loadUsers(page: _usersPage?.currentPage ?? 1, silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.warning('Cap nhat that bai', message: error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoa tai khoan'),
          content: Text(
            'Ban co chac muon xoa tai khoan ${user.employeeCode} - ${user.name}?',
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

    if (!mounted) {
      return;
    }

    try {
      final session = context.read<AppSession>();
      final message = await session.adminUserRepository.deleteUser(user.id);

      if (!mounted) return;

      AppToast.success('Xoa thanh cong', message: message);
      await _loadUsers(page: _usersPage?.currentPage ?? 1, silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.warning('Xoa that bai', message: error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.error('Co loi xay ra', message: error.toString());
    }
  }

  Future<void> _showUserForm({AdminUser? existing}) async {
    if (_roles.isEmpty) {
      AppToast.warning(
        'Chua san sang',
        message: 'Khong tai duoc danh sach role de tao tai khoan.',
      );
      return;
    }

    try {
      final session = context.read<AppSession>();
      final latestDepartments = await session.metaRepository.fetchDepartments();

      if (!mounted) return;

      setState(() {
        _departments = latestDepartments;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      AppToast.warning(
        'Khong tai duoc phong ban moi nhat',
        message: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error('Co loi xay ra', message: error.toString());
    }

    final formKey = GlobalKey<FormState>();
    final employeeCodeController = TextEditingController(
      text: existing?.employeeCode ?? '',
    );
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final passwordController = TextEditingController();

    final employeeRoleIds = _roles
        .where((role) => role.code == 'employee')
        .map((role) => role.id)
        .toList(growable: false);
    final int? employeeRoleId =
        employeeRoleIds.isEmpty ? null : employeeRoleIds.first;

    int? selectedRoleId = existing?.roleId ?? employeeRoleId ?? _roles.first.id;
    int? selectedDepartmentId = existing?.departmentId;
    bool isActive = existing?.isActive ?? true;
    bool isSubmitting = false;
    final availableDepartments = _departments
        .where(
          (department) =>
              department.isActive || department.id == selectedDepartmentId,
        )
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setModalState(() => isSubmitting = true);

              try {
                final session = context.read<AppSession>();

                if (existing == null) {
                  final result = await session.adminUserRepository.createUser(
                    roleId: selectedRoleId!,
                    departmentId: selectedDepartmentId,
                    employeeCode: employeeCodeController.text.trim(),
                    name: nameController.text.trim(),
                    email:
                        emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                    phone:
                        phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                    password: passwordController.text.trim(),
                    isActive: isActive,
                  );

                  if (!context.mounted) return;
                  Navigator.of(sheetContext).pop();
                  AppToast.success('Tao thanh cong', message: result.$1);
                } else {
                  final result = await session.adminUserRepository.updateUser(
                    existing.id,
                    roleId: selectedRoleId,
                    departmentId: selectedDepartmentId,
                    includeDepartment: true,
                    employeeCode: employeeCodeController.text.trim(),
                    name: nameController.text.trim(),
                    email:
                        emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                    phone:
                        phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                    password:
                        passwordController.text.trim().isEmpty
                            ? null
                            : passwordController.text.trim(),
                    isActive: isActive,
                  );

                  if (!context.mounted) return;
                  Navigator.of(sheetContext).pop();
                  AppToast.success('Cap nhat thanh cong', message: result.$1);
                }

                await _loadUsers(
                  page: _usersPage?.currentPage ?? 1,
                  silent: true,
                );
              } on ApiException catch (error) {
                if (!context.mounted) return;
                AppToast.warning(
                  existing == null ? 'Tao that bai' : 'Cap nhat that bai',
                  message: error.message,
                );
              } catch (error) {
                if (!context.mounted) return;
                AppToast.error('Co loi xay ra', message: error.toString());
              } finally {
                if (context.mounted) {
                  setModalState(() => isSubmitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null
                            ? 'Tao tai khoan nhan vien'
                            : 'Cap nhat tai khoan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        existing == null
                            ? 'Nhap thong tin can thiet de tao user moi cho he thong.'
                            : 'Chinh sua thong tin, password va trang thai hoat dong cua user.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: employeeCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Ma nhan vien',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui long nhap ma nhan vien.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: nameController,
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        decoration: const InputDecoration(
                          labelText: 'Vai tro',
                          prefixIcon: Icon(Icons.shield_rounded),
                        ),
                        items:
                            _roles
                                .map(
                                  (role) => DropdownMenuItem<int>(
                                    value: role.id,
                                    child: Text(role.name),
                                  ),
                                )
                                .toList(growable: false),
                        onChanged: (value) {
                          setModalState(() => selectedRoleId = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        value: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Phong ban',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Khong gan phong ban'),
                            ),
                            ...availableDepartments.map(
                              (department) => DropdownMenuItem<int?>(
                                value: department.id,
                                child: Text(department.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() => selectedDepartmentId = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'So dien thoai',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: existing == null ? 'Mat khau' : 'Mat khau moi',
                          hintText:
                              existing == null
                                  ? 'Toi thieu 8 ky tu'
                                  : 'Bo trong neu khong doi',
                          prefixIcon: const Icon(Icons.lock_rounded),
                        ),
                        validator: (value) {
                          if (existing == null &&
                              (value == null || value.trim().length < 8)) {
                            return 'Mat khau toi thieu 8 ky tu.';
                          }
                          if (existing != null &&
                              value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length < 8) {
                            return 'Mat khau moi toi thieu 8 ky tu.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (value) {
                          setModalState(() => isActive = value);
                        },
                        title: const Text('Tai khoan dang hoat dong'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              isSubmitting || selectedRoleId == null
                                  ? null
                                  : submit,
                          child:
                              isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    existing == null
                                        ? 'Tao tai khoan'
                                        : 'Luu thay doi',
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pagination() {
    final page = _usersPage;
    if (page == null || page.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                page.currentPage > 1
                    ? () => _loadUsers(page: page.currentPage - 1)
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
            onPressed:
                page.currentPage < page.lastPage
                    ? () => _loadUsers(page: page.currentPage + 1)
                    : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Sau'),
          ),
        ),
      ],
    );
  }

  Widget _userCard(AdminUser user) {
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
                child:
                    avatarProvider == null
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
                          label: user.role ?? user.roleCode ?? '--',
                          color: const Color(0xFFDBEAFE),
                        ),
                        StatusBadge(
                          label: user.isActive ? 'Dang hoat dong' : 'Da khoa',
                          color:
                              user.isActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
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
            'Email: ${user.email ?? 'Chua cap nhat'}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            'So dien thoai: ${user.phone ?? 'Chua cap nhat'}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Lan dang nhap: ${formatDateTime(user.lastLoginAt)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUserForm(existing: user),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Sua'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleUserStatus(user),
                  icon: Icon(
                    user.isActive
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                  ),
                  label: Text(user.isActive ? 'Khoa' : 'Mo khoa'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _deleteUser(user),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Xoa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _usersPage == null) {
      final loadingBody = const Center(child: CircularProgressIndicator());
      return widget.embedded ? loadingBody : SafeArea(child: loadingBody);
    }

    final users = _usersPage?.data ?? const <AdminUser>[];

    final heroCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33115E59),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
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
                      'Quan ly tai khoan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin co the tao moi, chinh sua, khoa mo va xoa tai khoan nhan vien ngay trong ung dung.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _showUserForm(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F766E),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tong so tai khoan: ${_usersPage?.total ?? users.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );

    final filterCard = SectionCard(
      title: 'Bo loc va thao tac nhanh',
      subtitle: 'Tim kiem theo ma nhan vien, ho ten, email hoac so dien thoai.',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadUsers(),
            decoration: InputDecoration(
              labelText: 'Tim user',
              hintText: 'VD: nv001, Nguyen Van A...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () => _loadUsers(),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _roleCodeFilter,
                  decoration: const InputDecoration(labelText: 'Vai tro'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tat ca'),
                    ),
                    ..._roles.map(
                      (role) => DropdownMenuItem<String?>(
                        value: role.code,
                        child: Text(role.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _roleCodeFilter = value);
                    _loadUsers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: _activeFilter,
                  decoration: const InputDecoration(labelText: 'Trang thai'),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('Tat ca'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('Dang hoat dong'),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('Da khoa'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _activeFilter = value);
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final errorCard = _errorMessage == null
        ? null
        : SectionCard(
            title: 'Can kiem tra lai',
            subtitle: 'Khong tai duoc danh sach user hien tai.',
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
          );

    final listCard = SectionCard(
      title: 'Danh sach tai khoan',
      subtitle: 'Theo doi va cap nhat tai khoan nhan vien trong he thong.',
      child: users.isEmpty
          ? const Text('Chua co tai khoan phu hop voi bo loc hien tai.')
          : Column(
              children: users.map(_userCard).toList(growable: false),
            ),
    );

    final body = RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          heroCard,
          const SizedBox(height: 16),
          filterCard,
          if (errorCard != null) ...[
            const SizedBox(height: 16),
            errorCard,
          ],
          const SizedBox(height: 16),
          listCard,
          const SizedBox(height: 16),
          _pagination(),
        ],
      ),
    );

    return widget.embedded ? body : SafeArea(child: body);
  }
}
