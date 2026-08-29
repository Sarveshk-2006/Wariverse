import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wari_colors.dart';

/// Centralized typography system for WariVerse AI.
/// Uses Plus Jakarta Sans (primary) and Noto Sans Devanagari (Marathi/Hindi).
/// Mirrors the font hierarchy from globals.css.
abstract class WariTypography {
  // ── Font Families ──────────────────────────────────────────────
  static TextStyle get _plusJakarta => GoogleFonts.plusJakartaSans();
  static TextStyle get _notoDevanagari => GoogleFonts.notoSansDevanagari();

  /// Returns the appropriate base font for [locale].
  static TextStyle baseFor(Locale? locale) {
    if (locale?.languageCode == 'mr' || locale?.languageCode == 'hi') {
      return _notoDevanagari;
    }
    return _plusJakarta;
  }

  // ── Display & Heading Styles ───────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: WariColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: WariColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: WariColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: WariColors.textPrimary,
        height: 1.35,
      );

  // ── Title Styles ───────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: WariColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WariColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: WariColors.textSecondary,
        height: 1.4,
      );

  // ── Body Styles ────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: WariColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: WariColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: WariColors.textMuted,
        height: 1.5,
      );

  // ── Label Styles ───────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WariColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: WariColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: WariColors.textMuted,
        letterSpacing: 0.3,
      );

  // ── Specialty Styles ───────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: WariColors.textMuted,
        height: 1.4,
      );

  static TextStyle get statValue => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: WariColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get statLabel => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: WariColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle get alertTitle => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: WariColors.textPrimary,
      );

  static TextStyle get chipLabel => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get appBarTitle => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: WariColors.textOnPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get buttonLabel => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  // ── Build TextTheme for MaterialApp ───────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
