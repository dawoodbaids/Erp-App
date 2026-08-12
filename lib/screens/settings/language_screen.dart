import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../widgets/ui/app_appbar.dart';
import '../../widgets/ui/app_tile.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppAppBar(title: 'language.title'.tr),
      body: GetX<SettingsController>(
        builder: (controller) {
          final current = controller.locale.languageCode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                'language.subtitle'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AppGroupCard(
                children: [
                  _LanguageTile(
                    label: 'language.english'.tr,
                    subtitle: 'language.englishSubtitle'.tr,
                    selected: current == 'en',
                    onTap: () => controller.setLocale(const Locale('en')),
                  ),
                  AppDivider(),
                  _LanguageTile(
                    label: 'language.arabic'.tr,
                    subtitle: 'language.arabicSubtitle'.tr,
                    selected: current == 'ar',
                    onTap: () => controller.setLocale(const Locale('ar')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.translate_rounded,
                color: theme.colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                size: 20,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}
