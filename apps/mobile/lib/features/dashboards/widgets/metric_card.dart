import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';

/// Scannable operational KPI metric card.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = WariColors.primary,
    this.subtext,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    return WariCard(
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: WariTypography.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: WariSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: WariTypography.labelSmall),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(
                subtext!,
                style: WariTypography.caption.copyWith(fontSize: 10, color: WariColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
