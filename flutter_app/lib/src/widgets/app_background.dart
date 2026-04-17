import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F8F4),
                  Color(0xFFEAF0EB),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -40,
          child: _GlowOrb(
            size: 240,
            colors: const [
              Color(0x3323B38A),
              Color(0x0023B38A),
            ],
          ),
        ),
        Positioned(
          top: 120,
          left: -90,
          child: _GlowOrb(
            size: 200,
            colors: const [
              Color(0x2D205D71),
              Color(0x00205D71),
            ],
          ),
        ),
        Positioned(
          bottom: -90,
          right: -70,
          child: _GlowOrb(
            size: 220,
            colors: const [
              Color(0x2AC2A66B),
              Color(0x00C2A66B),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
