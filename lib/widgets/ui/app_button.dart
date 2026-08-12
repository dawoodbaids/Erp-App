import 'package:flutter/material.dart';

enum AppButtonVariant { filled, tonal, outline, danger, text }

/// Consistent action button used across the app.
class AppButton extends StatelessWidget {
  final AppButtonVariant variant;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !loading;

    final Widget content = loading
        ? const _ButtonLoader()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final style = _styleFor(context, theme, enabled);

    Widget button;
    switch (variant) {
      case AppButtonVariant.filled:
        button = FilledButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.tonal:
        button = FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: content,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: content,
        );
    }

    if (!expanded) return button;

    return SizedBox(
      width: double.infinity,
      height: height ?? 50,
      child: button,
    );
  }

  ButtonStyle? _styleFor(BuildContext context, ThemeData theme, bool enabled) {
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    switch (variant) {
      case AppButtonVariant.filled:
        return null;
      case AppButtonVariant.tonal:
        return null;
      case AppButtonVariant.danger:
        return FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          disabledBackgroundColor: scheme.error.withValues(alpha: 0.35),
          disabledForegroundColor: scheme.onError.withValues(alpha: 0.8),
        );
      case AppButtonVariant.outline:
        return null;
      case AppButtonVariant.text:
        return TextButton.styleFrom(
          foregroundColor: isDark ? scheme.primary : scheme.primary,
        );
    }
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    final color = switch (DefaultTextStyle.of(context).style.color) {
      final value? => value,
      null => Theme.of(context).colorScheme.onPrimary,
    };
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    );
  }
}
