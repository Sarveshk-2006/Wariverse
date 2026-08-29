import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Section header with optional "See All" action — mirrors web dashboard headings.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: WariSpacing.base,
            vertical: WariSpacing.sm,
          ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: WariColors.primary),
            const SizedBox(width: WariSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WariTypography.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: WariTypography.caption),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: WariSpacing.sm,
                  vertical: WariSpacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: WariTypography.labelMedium.copyWith(
                  color: WariColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
