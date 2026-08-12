import 'package:flutter/material.dart';

/// Design tokens for RP ERP (Phase 1 redesign).
///
/// A single strong indigo brand color on clean cool neutrals, with a curated
/// set of semantic status colors. Dark mode uses tuned navy surfaces rather
/// than a naive inversion of the light palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4A53D1);
  static const Color primaryPressed = Color(0xFF3A42B5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primarySoft = Color(0xFFE9EBFA);
  static const Color primarySoftDark = Color(0xFF23284D);

  // Light neutrals
  static const Color backgroundLight = Color(0xFFF6F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color fillLight = Color(0xFFF3F4F6);
  static const Color scaffoldLight = Color(0xFFF6F7FB);

  // Dark neutrals
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF121827);
  static const Color surfaceRaisedDark = Color(0xFF1B2233);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFA0AAB9);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color borderDark = Color(0xFF232B3D);
  static const Color fillDark = Color(0xFF171F2F);
  static const Color scaffoldDark = Color(0xFF0B0F19);

  // Status — Draft (warning)
  static const Color draft = Color(0xFFB45309);
  static const Color draftSoft = Color(0xFFFDF0DC);
  static const Color draftDark = Color(0xFFF7B955);
  static const Color draftSoftDark = Color(0xFF2A2112);

  // Status — Approved (success)
  static const Color approved = Color(0xFF15803D);
  static const Color approvedSoft = Color(0xFFE3F4E9);
  static const Color approvedDark = Color(0xFF5CD08A);
  static const Color approvedSoftDark = Color(0xFF102A1A);

  // Status — Cancelled (error)
  static const Color cancelled = Color(0xFFDC2626);
  static const Color cancelledSoft = Color(0xFFFDE7E7);
  static const Color cancelledDark = Color(0xFFF58078);
  static const Color cancelledSoftDark = Color(0xFF2E1414);

  // Semantic aliases
  static const Color success = approved;
  static const Color successSoft = approvedSoft;
  static const Color warning = draft;
  static const Color warningSoft = draftSoft;
  static const Color error = cancelled;
  static const Color errorSoft = cancelledSoft;
  static const Color info = Color(0xFF0E7490);
  static const Color infoSoft = Color(0xFFE0F2F8);

  // Misc
  static const Color subtleBrand = Color(0xFFEEF0FA);
  static const Color scrim = Color(0x66000000);
  static const List<Color> avatarPalette = [
    primary,
    Color(0xFF0E9F6E),
    Color(0xFFC4541B),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFBE185D),
  ];

  // Elevation
  static const Color shadowLight = Color(0x1A0F172A);
  static const Color shadowDark = Color(0x00000000);

  // Hero gradient
  static const Color brandStart = Color(0xFF5B63DB);
  static const Color brandEnd = Color(0xFF3A42B5);
  static const Color heroOverlay = Color(0x14FFFFFF);
  static const Color heroOverlayStrong = Color(0x26FFFFFF);

  // Skeleton
  static const Color skeletonLight = Color(0xFFE7EAF2);
  static const Color skeletonDark = Color(0xFF202839);
  static const Color skeletonHighlightLight = Color(0xFFF4F6FA);
  static const Color skeletonHighlightDark = Color(0xFF293245);
}
