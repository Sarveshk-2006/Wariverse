import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Standard WariVerse content card with Apple iOS/macOS Glassmorphism visual design.
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
    this.enableGlass = true,
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
  final bool enableGlass;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? 18.0;
    final effectivePadding = padding ?? const EdgeInsets.all(WariSpacing.cardPadding);
    final cardColor = color ?? (enableGlass ? WariColors.surface.withValues(alpha: 0.92) : WariColors.surface);

    Widget innerContent = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: borderColor ?? WariColors.border.withValues(alpha: 0.8),
          width: borderWidth,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: enableGlass
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: innerContent,
            )
          : innerContent,
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

