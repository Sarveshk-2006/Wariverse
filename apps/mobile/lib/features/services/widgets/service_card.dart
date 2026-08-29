import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/unified_service_item.dart';

/// Scannable pilgrim service card.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final UnifiedServiceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
      child: WariCard(
        borderColor: item.color.withValues(alpha: 0.3),
        borderWidth: 1.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 16, color: item.color),
                    ),
                    const SizedBox(width: WariSpacing.xs),
                    Text(
                      item.categoryLabel,
                      style: WariTypography.labelSmall.copyWith(
                        color: item.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                WariStatusChip(
                  label: item.availableNow ? '✓ OPEN' : 'CLOSED',
                  color: item.availableNow ? WariColors.success : WariColors.danger,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            Text(item.name, style: WariTypography.titleSmall),
            if (item.subtext != null) ...[
              const SizedBox(height: 2),
              Text(item.subtext!, style: WariTypography.caption),
            ],
            const SizedBox(height: WariSpacing.sm),

            Row(
              children: [
                if (item.distanceM != null) ...[
                  Icon(Icons.near_me, size: 12, color: WariColors.slate500),
                  const SizedBox(width: 2),
                  Text(
                    '${WariFormatters.formatDistance(item.distanceM!.toDouble())} · ~${item.walkMinutes ?? 2}m',
                    style: WariTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
                if (item.queueMinutes != null) ...[
                  const SizedBox(width: WariSpacing.base),
                  Icon(Icons.schedule, size: 12, color: WariColors.warningDark),
                  const SizedBox(width: 2),
                  Text(
                    'Queue: ${item.queueMinutes} min',
                    style: WariTypography.bodySmall.copyWith(
                      color: item.queueMinutes! > 15 ? WariColors.danger : WariColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (item.rating != null) ...[
                  const Spacer(),
                  Icon(Icons.star, size: 12, color: WariColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    '${item.rating}',
                    style: WariTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),

            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: WariSpacing.xs),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WariColors.slate100,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                    ),
                    child: Text(
                      tag,
                      style: WariTypography.caption.copyWith(fontSize: 10, color: WariColors.slate700),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
