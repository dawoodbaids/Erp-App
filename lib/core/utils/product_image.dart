import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

Widget buildProductImage(
  String? image, {
  double size = 48,
  BoxFit fit = BoxFit.cover,
  BuildContext? context,
}) {
  final theme = context == null ? null : Theme.of(context);
  final placeholderBackground =
      theme?.colorScheme.surfaceContainerHigh ?? AppColors.fillLight;
  final placeholderForeground =
      theme?.colorScheme.onSurfaceVariant ?? AppColors.textSecondaryLight;
  final placeholder = ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Container(
      width: size,
      height: size,
      color: placeholderBackground,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.5,
        color: placeholderForeground,
      ),
    ),
  );

  if (image == null || image.isEmpty || !image.startsWith('http')) {
    return placeholder;
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Image.network(
      image,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    ),
  );
}
