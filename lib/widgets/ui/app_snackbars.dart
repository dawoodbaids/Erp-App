import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';

/// Consistent success / error / info snackbars.
class AppSnack {
  AppSnack._();

  static void success(String message, {String? title}) {
    _show(title ?? 'common.success'.tr, message, AppColors.approved);
  }

  static void error(String message, {String? title}) {
    _show(title ?? 'common.error'.tr, message, AppColors.cancelled);
  }

  static void info(String message, {String? title}) {
    _show(title ?? 'common.info'.tr, message, AppColors.primary);
  }

  static void _show(String title, String message, Color accent) {
    final isDark = Get.isDarkMode;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isDark ? AppColors.surfaceRaisedDark : Colors.white,
      colorText: isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight,
      titleText: Text(
        title,
        style: TextStyle(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          fontSize: 13.5,
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 14,
      borderColor: accent.withValues(alpha: 0.35),
      borderWidth: 1,
      icon: Icon(_iconFor(accent), color: accent, size: 22),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 220),
    );
  }

  static IconData _iconFor(Color color) {
    if (color == AppColors.approved) return Icons.check_circle_rounded;
    if (color == AppColors.cancelled) return Icons.error_rounded;
    return Icons.info_rounded;
  }
}
