import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Unified card surface used across the app.
///
/// Provides a consistent corner radius, border and a soft shadow so every
/// screen shares the same premium surface language.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final bool padded;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.padded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = color ?? theme.colorScheme.surface;

    final decoration = BoxDecoration(
      color: background,
      borderRadius: AppRadius.card,
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: AppColors.shadowLight.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
    );

    final content = padded
        ? Padding(padding: padding, child: child)
        : SizedBox(width: double.infinity, child: child);

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.card,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.card,
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(margin: margin, decoration: decoration, child: content);
  }
}
