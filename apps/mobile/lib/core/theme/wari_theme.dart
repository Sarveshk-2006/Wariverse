import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wari_colors.dart';
import 'wari_typography.dart';
import 'wari_spacing.dart';

/// WariVerse AI Material 3 ThemeData factory.
/// Call [WariTheme.light] and pass the result to [MaterialApp.theme].
abstract class WariTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: WariColors.lightColorScheme,
        textTheme: WariTypography.textTheme,
        scaffoldBackgroundColor: WariColors.background,

        // ── AppBar ───────────────────────────────────────────────
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: WariColors.primary,
          foregroundColor: WariColors.textOnPrimary,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: WariTypography.appBarTitle,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          iconTheme: const IconThemeData(
            color: WariColors.textOnPrimary,
            size: 24,
          ),
        ),

        // ── Bottom Navigation Bar ────────────────────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: WariColors.surface,
          selectedItemColor: WariColors.primary,
          unselectedItemColor: WariColors.slate400,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),

        // ── Navigation Bar (Material 3) ──────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: WariColors.surface,
          indicatorColor: WariColors.primaryLight.withValues(alpha: 0.18),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: WariColors.primary, size: 22);
            }
            return const IconThemeData(color: WariColors.slate400, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return WariTypography.labelSmall.copyWith(
                color: WariColors.primary,
                fontWeight: FontWeight.w700,
              );
            }
            return WariTypography.labelSmall;
          }),
          elevation: 8,
          surfaceTintColor: Colors.transparent,
        ),

        // ── Card ─────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: WariColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: WariSpacing.elevationSm,
          shadowColor: WariColors.slate900.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            side: const BorderSide(color: WariColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated Button ───────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WariColors.primary,
            foregroundColor: WariColors.textOnPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, WariSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: WariSpacing.xl,
              vertical: WariSpacing.md,
            ),
            textStyle: WariTypography.buttonLabel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            ),
          ),
        ),

        // ── Outlined Button ───────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: WariColors.primary,
            side: const BorderSide(color: WariColors.primary, width: 1.5),
            minimumSize: const Size(double.infinity, WariSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: WariSpacing.xl,
              vertical: WariSpacing.md,
            ),
            textStyle: WariTypography.buttonLabel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            ),
          ),
        ),

        // ── Text Button ───────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: WariColors.primary,
            textStyle: WariTypography.labelLarge,
            minimumSize: const Size(0, WariSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: WariSpacing.base,
              vertical: WariSpacing.sm,
            ),
          ),
        ),

        // ── Chip ─────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: WariColors.slate100,
          selectedColor: WariColors.primaryLight.withValues(alpha: 0.2),
          labelStyle: WariTypography.chipLabel.copyWith(
            color: WariColors.textSecondary,
          ),
          side: const BorderSide(color: WariColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: WariSpacing.md,
            vertical: WariSpacing.xs,
          ),
        ),

        // ── Input Decoration ──────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WariColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WariSpacing.base,
            vertical: WariSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            borderSide: const BorderSide(color: WariColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            borderSide: const BorderSide(color: WariColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            borderSide: const BorderSide(color: WariColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            borderSide: const BorderSide(color: WariColors.danger),
          ),
          hintStyle: WariTypography.bodyMedium.copyWith(
            color: WariColors.textMuted,
          ),
          labelStyle: WariTypography.labelMedium,
        ),

        // ── Divider ───────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: WariColors.border,
          thickness: 1,
          space: 1,
        ),

        // ── List Tile ─────────────────────────────────────────────
        listTileTheme: ListTileThemeData(
          tileColor: WariColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WariSpacing.base,
            vertical: WariSpacing.xs,
          ),
          minLeadingWidth: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
          ),
        ),

        // ── Floating Action Button ────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: WariColors.primary,
          foregroundColor: WariColors.textOnPrimary,
          elevation: 4,
        ),

        // ── Bottom Sheet ──────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: WariColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(WariSpacing.radiusXl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: WariColors.slate300,
        ),

        // ── Dialog ────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: WariColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
          ),
          elevation: 8,
          titleTextStyle: WariTypography.headlineSmall,
          contentTextStyle: WariTypography.bodyMedium,
        ),

        // ── Snack Bar ─────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: WariColors.slate900,
          contentTextStyle: WariTypography.bodyMedium.copyWith(
            color: WariColors.textOnDark,
          ),
          actionTextColor: WariColors.primaryLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
          ),
        ),

        // ── Icon ──────────────────────────────────────────────────
        iconTheme: const IconThemeData(
          color: WariColors.textSecondary,
          size: WariSpacing.iconSizeLg,
        ),
      );
}

