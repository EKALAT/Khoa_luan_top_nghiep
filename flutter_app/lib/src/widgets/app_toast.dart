import 'dart:async';

import 'package:flutter/material.dart';

import '../core/utils/app_navigator.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(String title, {String? message}) {
    _show(type: AppToastType.success, title: title, message: message);
  }

  static void error(String title, {String? message}) {
    _show(type: AppToastType.error, title: title, message: message);
  }

  static void info(String title, {String? message}) {
    _show(type: AppToastType.info, title: title, message: message);
  }

  static void warning(String title, {String? message}) {
    _show(type: AppToastType.warning, title: title, message: message);
  }

  static void activity({
    required String title,
    String? message,
    String? avatarUrl,
    String? name,
    String? employeeCode,
    String? department,
    AppToastType type = AppToastType.info,
  }) {
    _show(
      type: type,
      title: title,
      message: message,
      avatarUrl: avatarUrl,
      actorName: name,
      actorCode: employeeCode,
      actorDepartment: department,
    );
  }

  static void _show({
    required AppToastType type,
    required String title,
    String? message,
    String? avatarUrl,
    String? actorName,
    String? actorCode,
    String? actorDepartment,
  }) {
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      return;
    }

    _timer?.cancel();
    _entry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (context) => _ToastOverlay(
            type: type,
            title: title,
            message: message,
            avatarUrl: avatarUrl,
            actorName: actorName,
            actorCode: actorCode,
            actorDepartment: actorDepartment,
            onDismissed: () {
              if (_entry == entry) {
                _entry = null;
              }
            },
          ),
    );

    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 3), () {
      if (_entry == entry) {
        entry.remove();
        _entry = null;
      }
    });
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.type,
    required this.title,
    required this.message,
    required this.avatarUrl,
    required this.actorName,
    required this.actorCode,
    required this.actorDepartment,
    required this.onDismissed,
  });

  final AppToastType type;
  final String title;
  final String? message;
  final String? avatarUrl;
  final String? actorName;
  final String? actorCode;
  final String? actorDepartment;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    return switch (widget.type) {
      AppToastType.success => const Color(0xFF15936F),
      AppToastType.error => const Color(0xFFCB5A32),
      AppToastType.info => const Color(0xFF265D8F),
      AppToastType.warning => const Color(0xFFB58111),
    };
  }

  IconData get _icon {
    return switch (widget.type) {
      AppToastType.success => Icons.check_circle_rounded,
      AppToastType.error => Icons.error_rounded,
      AppToastType.info => Icons.info_rounded,
      AppToastType.warning => Icons.warning_amber_rounded,
    };
  }

  bool get _hasActorInfo {
    return (widget.actorName ?? '').trim().isNotEmpty ||
        (widget.actorCode ?? '').trim().isNotEmpty ||
        (widget.actorDepartment ?? '').trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider =
        (widget.avatarUrl ?? '').trim().isEmpty
            ? null
            : NetworkImage(widget.avatarUrl!.trim());
    final actorSeed =
        (widget.actorName ?? widget.actorCode ?? widget.title).trim();
    final subtitleParts = <String>[
      if ((widget.actorCode ?? '').trim().isNotEmpty) widget.actorCode!.trim(),
      if ((widget.actorDepartment ?? '').trim().isNotEmpty)
        widget.actorDepartment!.trim(),
    ];

    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: SafeArea(
        child: IgnorePointer(
          ignoring: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102229),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3D0A1E25),
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_icon, color: _accentColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if ((widget.message ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                if (_hasActorInfo) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFFDBEAFE),
                                          backgroundImage: avatarProvider,
                                          child: avatarProvider == null
                                              ? Text(
                                                  actorSeed.isEmpty
                                                      ? '?'
                                                      : actorSeed[0].toUpperCase(),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (widget.actorName ?? '').trim().isEmpty
                                                    ? 'Nhan vien'
                                                    : widget.actorName!.trim(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                              ),
                                              if (subtitleParts.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  subtitleParts.join(' | '),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white
                                                            .withValues(
                                                          alpha: 0.72,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
