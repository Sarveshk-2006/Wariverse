import 'package:flutter/material.dart';

/// Centralized color palette for WariVerse AI.
/// Mirrors the Sacred Saffron design system from globals.css.
/// Never hard-code these values in feature widgets — always reference WariColors.
abstract class WariColors {
  // ── Primary Brand ──────────────────────────────────────────────
  /// Sacred Saffron / Ember — primary brand color
  static const Color primary = Color(0xFFD97706);
  static const Color primaryLight = Color(0xFFF59E0B);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color accent = Color(0xFFC2410C);

  // ── Backgrounds & Surfaces ─────────────────────────────────────
  /// Warm devotional neutral background with Apple system grey feel
  static const Color background = Color(0xFFF2F4F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color glassSurface = Color(0xEBF8FAFC);
  static const Color glassBorder = Color(0x60FFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // ── Typography ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Status / Functional ────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerDark = Color(0xFF991B1B);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Crowd Safety Levels ────────────────────────────────────────
  static const Color crowdGreen = Color(0xFF16A34A);
  static const Color crowdGreenLight = Color(0xFFDCFCE7);
  static const Color crowdYellow = Color(0xFFCA8A04);
  static const Color crowdYellowLight = Color(0xFFFEF9C3);
  static const Color crowdOrange = Color(0xFFEA580C);
  static const Color crowdOrangeLight = Color(0xFFFFEDD5);
  static const Color crowdRed = Color(0xFFDC2626);
  static const Color crowdRedLight = Color(0xFFFEE2E2);

  // ── Neutral Scale ──────────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ── Service Category Colors ────────────────────────────────────
  static const Color foodColor = Color(0xFFD97706);
  static const Color waterColor = Color(0xFF2563EB);
  static const Color medicalColor = Color(0xFFDC2626);
  static const Color toiletColor = Color(0xFF0891B2);
  static const Color shelterColor = Color(0xFF7C3AED);
  static const Color wellnessColor = Color(0xFF16A34A);
  static const Color sosColor = Color(0xFFDC2626);

  // ── Saffron Glow Shadow (matches --shadow-saffron in CSS) ──────
  static const Color saffronShadow = Color(0x40D97706);

  // ── ColorScheme factory ────────────────────────────────────────
  static ColorScheme get lightColorScheme => ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: textOnPrimary,
        primaryContainer: Color(0xFFFEF3C7),
        onPrimaryContainer: primaryDark,
        secondary: accent,
        onSecondary: textOnPrimary,
        secondaryContainer: Color(0xFFFFEDD5),
        onSecondaryContainer: accent,
        tertiary: success,
        onTertiary: textOnPrimary,
        tertiaryContainer: successLight,
        onTertiaryContainer: Color(0xFF14532D),
        error: danger,
        onError: textOnPrimary,
        errorContainer: dangerLight,
        onErrorContainer: Color(0xFF7F1D1D),
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: background,
        onSurfaceVariant: textSecondary,
        outline: border,
        outlineVariant: borderSubtle,
        shadow: Color(0x140F172A),
        scrim: Color(0x800F172A),
        inverseSurface: slate900,
      );
}
