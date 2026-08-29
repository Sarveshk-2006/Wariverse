import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Standard WariVerse content card.
/// Preserves the rounded, bordered, soft-shadow card style from the web.
class WariCard extends StatelessWidget {
  const WariCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.radius,
    this.elevation = WariSpacing.elevationSm,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double? radius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? WariSpacing.radiusMd;
    final effectivePadding = padding ??
        const EdgeInsets.all(WariSpacing.cardPadding);

    Widget card = Container(
      decoration: BoxDecoration(
        color: color ?? WariColors.surface,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ?? WariColors.border,
          width: borderWidth,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: WariColors.slate900.withValues(alpha: 0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// Highlighted WariVerse card with a colored left accent border.
class WariAccentCard extends StatelessWidget {
  const WariAccentCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final Color accentColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return WariCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(WariSpacing.radiusMd),
                  bottomLeft: Radius.circular(WariSpacing.radiusMd),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: padding ??
                    const EdgeInsets.all(WariSpacing.cardPadding),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

