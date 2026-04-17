import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_session.dart';
import '../widgets/app_background.dart';
import '../widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final session = context.read<AppSession>();
    final success = await session.login(
      employeeCode: _employeeCodeController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      AppToast.success(
        'Dang nhap thanh cong',
        message: 'Chao mung ban quay tro lai voi Smart Attendance.',
      );
      return;
    }

    AppToast.error(
      'Dang nhap that bai',
      message: session.errorMessage ?? 'Vui long kiem tra lai thong tin.',
    );
  }

  Future<void> _showBaseUrlSheet() async {
    final session = context.read<AppSession>();
    final controller = TextEditingController(text: session.baseUrl);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cau hinh may chu',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhap dia chi backend local, public hoac ngrok. Neu thieu /api thi app se tu them.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://10.0.2.2:8000/api',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Android Emulator dung http://10.0.2.2:8000. May that nen dung public URL hoac IP cung mang.',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(sheetContext);
                    await session.updateBaseUrl(controller.text);
                    navigator.pop();
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

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 820;

                    final hero = Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F3D78),
                            Color(0xFF1D4ED8),
                            Color(0xFF2563EB),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331D4ED8),
                            blurRadius: 34,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: const Text(
                              'SMART ATTENDANCE PMS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x260F172A),
                                      blurRadius: 18,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/icon/app_icon_foreground.png',
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    isAntiAlias: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dang nhap de bat dau\nphien cham cong an toan.',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            height: 1.15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'He thong xac thuc GPS, geofence va network truoc khi ghi nhan du lieu cham cong.',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.84,
                                            ),
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _statusChip(
                                icon: Icons.gps_fixed_rounded,
                                label: 'GPS xac thuc',
                                color: const Color(0x1FECFEFF),
                                foreground: Colors.white,
                              ),
                              _statusChip(
                                icon: Icons.location_on_rounded,
                                label: 'Geofence doi chieu',
                                color: const Color(0x1FFEF3C7),
                                foreground: Colors.white,
                              ),
                              _statusChip(
                                icon: Icons.wifi_tethering_rounded,
                                label: 'Network kiem tra',
                                color: const Color(0x1FDCFCE7),
                                foreground: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Column(
                            children: [
                              _featureTile(
                                icon: Icons.shield_rounded,
                                title: 'Bao toan tinh hop le',
                                subtitle:
                                    'Chan check trung, sai gio va thieu moc cham cong trong ngay.',
                              ),
                              const SizedBox(height: 12),
                              _featureTile(
                                icon: Icons.history_toggle_off_rounded,
                                title: 'Dong bo nhanh lich su',
                                subtitle:
                                    'Nhan vien theo doi ngay trong app, admin co the kiem tra toan bo he thong.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final form = Consumer<AppSession>(
                      builder: (context, session, _) {
                        return Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x100F172A),
                                blurRadius: 28,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tai khoan he thong',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      const Color(0xFF0F172A),
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Nhap ma nhan vien va mat khau de truy cap ung dung.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      const Color(0xFF64748B),
                                                  height: 1.45,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton.filledTonal(
                                      onPressed: _showBaseUrlSheet,
                                      icon: const Icon(Icons.tune_rounded),
                                      tooltip: 'Cau hinh may chu',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF8FAFC),
                                        Color(0xFFEFF6FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFDBEAFE),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.dns_rounded,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Backend dang ket noi',
                                              style: TextStyle(
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              session.baseUrl,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        const Color(0xFF334155),
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (session.errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFFED7AA),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 20,
                                          color: Color(0xFFEA580C),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            session.errorMessage!,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      const Color(0xFF9A3412),
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.45,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _employeeCodeController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Ma nhan vien',
                                    hintText: 'VD: nv001',
                                    prefixIcon: Icon(Icons.badge_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Vui long nhap ma nhan vien.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Mat khau',
                                    prefixIcon: const Icon(Icons.lock_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui long nhap mat khau.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Luu y truoc khi dang nhap',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Ung dung se su dung tai khoan dang duoc cap trong he thong. Phan demo dang nhap nhanh da duoc go bo de giao dien gon hon.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF64748B),
                                              height: 1.55,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed:
                                        session.isBusy ? null : _submit,
                                    child: session.isBusy
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Dang nhap he thong'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          hero,
                          const SizedBox(height: 20),
                          form,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 12, child: hero),
                        const SizedBox(width: 20),
                        Expanded(flex: 10, child: form),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
