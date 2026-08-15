import 'package:flutter/material.dart';

/// Design tokens for RP ERP ("Oceanic" redesign).
///
/// A confident electric-cyan brand on deep navy surfaces, with a curated
/// set of semantic status colors. Dark mode uses tuned ocean-plum surfaces
/// rather than a naive inversion of the light palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00838F);
  static const Color primaryPressed = Color(0xFF006064);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primarySoft = Color(0xFFE0F3F5);
  static const Color primarySoftDark = Color(0xFF10383E);

  // Light neutrals
  static const Color backgroundLight = Color(0xFFF2F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F2431);
  static const Color textSecondaryLight = Color(0xFF52677A);
  static const Color textTertiaryLight = Color(0xFF8CA2B4);
  static const Color borderLight = Color(0xFFE2EBF1);
  static const Color fillLight = Color(0xFFEBF2F7);
  static const Color scaffoldLight = Color(0xFFF2F7FA);

  // Dark neutrals
  static const Color backgroundDark = Color(0xFF081218);
  static const Color surfaceDark = Color(0xFF0F1B26);
  static const Color surfaceRaisedDark = Color(0xFF162532);
  static const Color textPrimaryDark = Color(0xFFEDF4F8);
  static const Color textSecondaryDark = Color(0xFFA6B8C6);
  static const Color textTertiaryDark = Color(0xFF6E8190);
  static const Color borderDark = Color(0xFF233640);
  static const Color fillDark = Color(0xFF13212D);
  static const Color scaffoldDark = Color(0xFF081218);

  // Status — Draft
  static const Color draft = Color(0xFFF59E0B);
  static const Color draftSoft = Color(0xFFFFF4D6);
  static const Color draftDark = Color(0xFFFFC65C);
  static const Color draftSoftDark = Color(0xFF332710);

  // Status — Approved
  static const Color approved = Color(0xFF10B981);
  static const Color approvedSoft = Color(0xFFDDF8EF);
  static const Color approvedDark = Color(0xFF4ADEB0);
  static const Color approvedSoftDark = Color(0xFF102D25);

  // Status — Cancelled
  static const Color cancelled = Color(0xFFEF4444);
  static const Color cancelledSoft = Color(0xFFFFE4E4);
  static const Color cancelledDark = Color(0xFFFF7777);
  static const Color cancelledSoftDark = Color(0xFF351719);

  // Semantic aliases
  static const Color success = approved;
  static const Color successSoft = approvedSoft;

  static const Color warning = draft;
  static const Color warningSoft = draftSoft;

  static const Color error = cancelled;
  static const Color errorSoft = cancelledSoft;

  static const Color info = Color(0xFF2196F3);
  static const Color infoSoft = Color(0xFFE3F2FD);

  // Additional accent colors
  static const Color cyan = Color(0xFF00BCD4);
  static const Color cyanSoft = Color(0xFFDDF6FA);

  static const Color blue = Color(0xFF2196F3);
  static const Color blueSoft = Color(0xFFE3F2FD);

  static const Color violet = Color(0xFF7C4DFF);
  static const Color violetSoft = Color(0xFFEDE7F6);

  static const Color pink = Color(0xFFEC4899);
  static const Color pinkSoft = Color(0xFFFFE8F3);

  // Misc
  static const Color subtleBrand = Color(0xFFE0F3F5);
  static const Color scrim = Color(0x66000000);

  static const List<Color> avatarPalette = [
    primary,
    Color(0xFF00BCD4),
    Color(0xFF2196F3),
    Color(0xFF7C4DFF),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];

  // Elevation
  static const Color shadowLight = Color(0x12081E2E);
  static const Color shadowDark = Color(0x00000000);

  // Hero gradient
  static const Color brandStart = Color(0xFF0097A7);
  static const Color brandEnd = Color(0xFF1565C0);

  static const Color heroOverlay = Color(0x14FFFFFF);
  static const Color heroOverlayStrong = Color(0x26FFFFFF);

  // Skeleton
  static const Color skeletonLight = Color(0xFFE8EEF4);
  static const Color skeletonDark = Color(0xFF1C2A37);
  static const Color skeletonHighlightLight = Color(0xFFF5F8FB);
  static const Color skeletonHighlightDark = Color(0xFF243745);
}
