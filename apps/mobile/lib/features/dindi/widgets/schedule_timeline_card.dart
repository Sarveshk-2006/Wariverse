import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

/// Timeline card widget displaying a single micro-itinerary entry with clear status emphasis.
class ScheduleTimelineCard extends StatelessWidget {
  const ScheduleTimelineCard({
    super.key,
    required this.item,
    this.onViewOnMap,
  });

  final DindiScheduleItem item;
  final VoidCallback? onViewOnMap;

  @override
  Widget build(BuildContext context) {
    Color cardColor = WariColors.surface;
    Color borderColor = WariColors.border;
    double borderWidth = 1.0;

    if (item.isCurrent) {
      cardColor = WariColors.primaryLight.withValues(alpha: 0.4);
      borderColor = WariColors.primary;
      borderWidth = 2.0;
    } else if (item.isCompleted) {
      cardColor = WariColors.slate50;
      borderColor = WariColors.slate300;
    }

    return WariCard(
      color: cardColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(),
                  const SizedBox(width: WariSpacing.xs),
                  Text(
                    item.scheduledTime,
                    style: WariTypography.titleMedium.copyWith(
                      color: item.isCurrent ? WariColors.primaryDark : WariColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),

          Text(
            item.title,
            style: WariTypography.headlineSmall.copyWith(
              color: item.isCompleted ? WariColors.textMuted : WariColors.textPrimary,
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              style: WariTypography.bodySmall.copyWith(
                color: item.isCompleted ? WariColors.textMuted : WariColors.slate800,
              ),
            ),
          ],
          const SizedBox(height: WariSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: item.isCurrent ? WariColors.primary : WariColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.locationName,
                        style: WariTypography.labelSmall.copyWith(
                          color: item.isCurrent ? WariColors.primaryDark : WariColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              if (item.hasLocation && onViewOnMap != null)
                WariSecondaryButtonInline(
                  label: 'View on Map',
                  onPressed: onViewOnMap!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (item.isCompleted) {
      return const CircleAvatar(
        radius: 10,
        backgroundColor: WariColors.success,
        child: Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    if (item.isCurrent) {
      return const CircleAvatar(
        radius: 10,
        backgroundColor: WariColors.primary,
        child: Icon(Icons.play_arrow, size: 12, color: Colors.white),
      );
    }
    return const CircleAvatar(
      radius: 10,
      backgroundColor: WariColors.slate300,
      child: Icon(Icons.schedule, size: 12, color: WariColors.textMuted),
    );
  }

  Widget _buildStatusChip() {
    if (item.isCurrent) {
      return const WariStatusChip(
        label: 'ACTIVE NOW',
        color: WariColors.primary,
        dense: true,
      );
    }
    if (item.isCompleted) {
      return const WariStatusChip(
        label: 'COMPLETED',
        color: WariColors.success,
        dense: true,
      );
    }
    return const WariStatusChip(
      label: 'UPCOMING',
      color: WariColors.info,
      dense: true,
    );
  }
}
