import 'package:flutter/material.dart';

/// Central text style helpers.
///
/// The base typography lives in the [ThemeData] text theme; these helpers
/// provide the consistently used semantic styles so screens never hardcode
/// font sizes or weights.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle pageTitle(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineSmall!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3);

  static TextStyle pageSubtitle(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle sectionTitle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800);

  static TextStyle cardTitle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700);

  static TextStyle cardSubtitle(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle statValue(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);

  static TextStyle statLabel(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle emphasized(BuildContext context, {Color? color}) => Theme.of(
    context,
  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: color);

  static TextStyle muted(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle tiny(BuildContext context) => Theme.of(context)
      .textTheme
      .labelSmall!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle brandHero(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineMedium!
      .copyWith(color: Colors.white, fontWeight: FontWeight.w800);

  static TextStyle brandHeroLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );

  static TextStyle brandHeroSubtitle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall!.copyWith(color: Colors.white.withValues(alpha: 0.8));
}
