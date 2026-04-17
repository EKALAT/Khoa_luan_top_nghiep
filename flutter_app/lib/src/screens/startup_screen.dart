import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _controller.value;
    final floatOffset = math.sin(progress * math.pi * 2) * 10;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFEFFFF),
                Color(0xFFF7FAFD),
                Color(0xFFEAF0F7),
              ],
            ),
          ),
          child: Stack(
            children: [
              _Backdrop(progress: progress),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: _HeroLogo(progress: progress),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'PMS Smart Attendance',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF123A78),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dang chuan bi vao he thong',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _LoadingRing(progress: progress),
                          const SizedBox(height: 22),
                          _ProgressRail(progress: progress),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final waveA = math.sin(progress * math.pi * 2);
    final waveB = math.cos(progress * math.pi * 2);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120 + (waveA * 20),
            right: -80 + (waveB * 14),
            child: const _GlowOrb(
              size: 280,
              colors: [
                Color(0x2460A5FA),
                Color(0x0060A5FA),
              ],
            ),
          ),
          Positioned(
            left: -90 + (waveB * 14),
            bottom: -50 + (waveA * 16),
            child: const _GlowOrb(
              size: 260,
              colors: [
                Color(0x208AF5BA),
                Color(0x008AF5BA),
              ],
            ),
          ),
          Positioned(
            right: 30,
            top: 130,
            child: Transform.rotate(
              angle: 0.46,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x142563EB)),
                ),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: 170,
            child: Transform.rotate(
              angle: -0.26,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x1223B38A)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 1 + (math.sin(progress * math.pi * 2) * 0.015);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 314,
          height: 314,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0x2260A5FA),
                const Color(0x0060A5FA),
              ],
            ),
          ),
        ),
        Transform.scale(
          scale: scale,
          child: Container(
            width: 228,
            height: 228,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(56),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140B1F44),
                  blurRadius: 26,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/icon/app_icon_foreground.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingRing extends StatelessWidget {
  const _LoadingRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              value: null,
              color: const Color(0xFF60A5FA),
              backgroundColor: const Color(0x142563EB),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8AF5BA),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8AF5BA).withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 280,
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final highlightWidth = constraints.maxWidth * 0.36;
            final left = (constraints.maxWidth - highlightWidth) * progress;

            return Stack(
              children: [
                Container(color: const Color(0x182563EB)),
                Positioned(
                  left: left,
                  child: Container(
                    width: highlightWidth,
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x008AF5BA),
                          Color(0xFF60A5FA),
                          Color(0xFF123A78),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
