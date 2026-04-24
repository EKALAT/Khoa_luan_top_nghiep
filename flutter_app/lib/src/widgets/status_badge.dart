import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  Color get _resolvedTextColor {
    if (textColor != null) {
      return textColor!;
    }

    final luminance = color.computeLuminance();
    if (luminance > 0.72) {
      return const Color(0xFF0F172A);
    }
    if (luminance > 0.45) {
      return const Color(0xFF1E293B);
    }
    return color;
  }

  Color get _resolvedBackgroundColor {
    if (backgroundColor != null) {
      return backgroundColor!;
    }

    final luminance = color.computeLuminance();
    if (luminance > 0.72) {
      return color.withValues(alpha: 0.92);
    }
    if (luminance > 0.45) {
      return color.withValues(alpha: 0.22);
    }
    return color.withValues(alpha: 0.12);
  }

  Color get _resolvedBorderColor {
    if (borderColor != null) {
      return borderColor!;
    }

    final luminance = color.computeLuminance();
    if (luminance > 0.72) {
      return const Color(0xFFD6E2F5);
    }
    if (luminance > 0.45) {
      return color.withValues(alpha: 0.30);
    }
    return color.withValues(alpha: 0.26);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _resolvedBackgroundColor,
        border: Border.all(color: _resolvedBorderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _resolvedTextColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
