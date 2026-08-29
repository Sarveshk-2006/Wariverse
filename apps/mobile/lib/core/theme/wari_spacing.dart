/// Centralized spacing constants for WariVerse AI.
/// Use these instead of raw pixel values in feature widgets.
abstract class WariSpacing {
  // ── Base Spacing Scale ─────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 40.0;
  static const double xl4 = 48.0;
  static const double xl5 = 64.0;

  // ── Border Radii ───────────────────────────────────────────────
  /// 6px — tight elements like small chips
  static const double radiusSm = 6.0;
  /// 10px — standard cards and containers
  static const double radiusMd = 10.0;
  /// 14px — large cards and bottom sheets
  static const double radiusLg = 14.0;
  /// 20px — hero cards and overlay surfaces
  static const double radiusXl = 20.0;
  /// Full pill shape
  static const double radiusFull = 9999.0;

  // ── Elevation ─────────────────────────────────────────────────
  static const double elevationNone = 0.0;
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;

  // ── Touch Targets ─────────────────────────────────────────────
  static const double minTouchTarget = 48.0;
  static const double iconSize = 20.0;
  static const double iconSizeLg = 24.0;
  static const double iconSizeXl = 32.0;

  // ── Layout ────────────────────────────────────────────────────
  static const double screenPadding = 16.0;
  static const double cardPadding = 14.0;
  static const double bottomNavHeight = 60.0;
  static const double appBarHeight = 56.0;
}
