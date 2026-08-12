import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Consistent scaffold wrapper used by every screen.
///
/// Provides the shared background, SafeArea handling and a uniform way to
/// attach bottom sheets / snack bars. Keeps the background clean (no
/// decorative gradients) for a modern, minimal ERP feel.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final EdgeInsetsGeometry bodyPadding;
  final Color? backgroundColor;
  final bool safeTop;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bodyPadding = EdgeInsets.zero,
    this.backgroundColor,
    this.safeTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      appBar: appBar,
      body: SafeArea(
        top: safeTop && appBar == null,
        bottom: false,
        child: Padding(padding: bodyPadding, child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Convenience layout helper: vertical spacing wrapper.
class AppSpacer extends StatelessWidget {
  final double size;

  const AppSpacer(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// Consistent page-level horizontal padding.
class AppPagePadding extends StatelessWidget {
  final Widget child;

  const AppPagePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: AppSpacing.page, child: child);
  }
}
