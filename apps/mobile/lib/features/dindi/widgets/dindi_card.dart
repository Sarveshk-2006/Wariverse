import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

/// Card widget displaying Dindi overview metrics, route section, and actions.
class DindiCard extends StatelessWidget {
  const DindiCard({
    super.key,
    required this.dindi,
    this.isJoined = false,
    this.onTap,
    this.onJoin,
    this.onSchedule,
    this.onLiveRoute,
    this.onCommunity,
    this.onVoice,
    this.onHealthShield,
  });

  final Dindi dindi;
  final bool isJoined;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onSchedule;
  final VoidCallback? onLiveRoute;
  final VoidCallback? onCommunity;
  final VoidCallback? onVoice;
  final VoidCallback? onHealthShield;

  @override
  Widget build(BuildContext context) {
    return WariCard(
      borderColor: isJoined ? WariColors.primary : WariColors.border,
      borderWidth: isJoined ? 1.5 : 1.0,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(WariSpacing.xs),
                    decoration: BoxDecoration(
                      color: WariColors.primaryLight,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.groups, color: WariColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dindi.name,
                        style: WariTypography.titleMedium,
                      ),
                      Text(
                        'Pramukh: ${dindi.leaderName}',
                        style: WariTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              if (isJoined)
                const WariStatusChip(
                  label: 'JOINED',
                  color: WariColors.success,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          // Route info bar
          Container(
            padding: const EdgeInsets.all(WariSpacing.xs),
            decoration: BoxDecoration(
              color: WariColors.slate100,
              borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.route, size: 14, color: WariColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dindi.routeSection,
                    style: WariTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.xs),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: WariColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Halt: ${dindi.currentHalt}',
                    style: WariTypography.labelSmall,
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: WariColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${dindi.memberCount} Varkaris',
                    style: WariTypography.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (onHealthShield != null) ...[
                  WariSecondaryButtonInline(
                    label: 'Health Shield',
                    onPressed: onHealthShield!,
                  ),
                  const SizedBox(width: WariSpacing.xs),
                ],
                if (onVoice != null) ...[
                  WariSecondaryButtonInline(
                    label: 'Palkhi Voice',
                    onPressed: onVoice!,
                  ),
                  const SizedBox(width: WariSpacing.xs),
                ],
                if (onCommunity != null) ...[
                  WariSecondaryButtonInline(
                    label: 'Community',
                    onPressed: onCommunity!,
                  ),
                  const SizedBox(width: WariSpacing.xs),
                ],
                if (onLiveRoute != null) ...[
                  WariSecondaryButtonInline(
                    label: 'Live Route',
                    onPressed: onLiveRoute!,
                  ),
                  const SizedBox(width: WariSpacing.xs),
                ],
                if (onSchedule != null) ...[
                  WariSecondaryButtonInline(
                    label: 'Schedule',
                    onPressed: onSchedule!,
                  ),
                  const SizedBox(width: WariSpacing.xs),
                ],
                if (!isJoined && onJoin != null)
                  WariSecondaryButtonInline(
                    label: 'Join Dindi',
                    onPressed: onJoin!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
