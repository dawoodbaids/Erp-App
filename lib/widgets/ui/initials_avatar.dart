import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Subtle initials avatar for customers and people.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const InitialsAvatar({super.key, required this.name, this.size = 40});

  static const _palette = AppColors.avatarPalette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _initials(name);

    final colorIndex =
        name.codeUnits.fold<int>(0, (sum, c) => sum + c) % _palette.length;
    final base = _palette[colorIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? base.withValues(alpha: 0.28)
            : base.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: isDark ? base.withValues(alpha: 0.95) : base,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first[0].toUpperCase();
    final last = parts.last[0].toUpperCase();
    return '$first$last';
  }
}
