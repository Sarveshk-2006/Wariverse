import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/virtual_dindi_provider.dart';
import '../../../models/virtual_dindi_model.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/virtual_dindi_engine.dart';

/// Interactive Virtual Dindi Home Dashboard Card displaying live separation status, distance, and action controls.
class VirtualDindiHomeCard extends StatelessWidget {
  const VirtualDindiHomeCard({
    super.key,
    required this.onCreatePressed,
    required this.onJoinPressed,
    required this.onOpenMapPressed,
    required this.onDetailPressed,
  });

  final VoidCallback onCreatePressed;
  final VoidCallback onJoinPressed;
  final VoidCallback onOpenMapPressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final dindi = dindiProvider.activeDindi;

    if (dindi == null) {
      return _buildNotJoinedCard(context);
    }

    final state = dindiProvider.currentSeparationState;
    final trend = dindiProvider.currentTrend;
    final networkStatus = dindiProvider.networkStatus;

    Color stateColor;
    IconData stateIcon;
    switch (state) {
      case SeparationState.SAFE:
        stateColor = WariColors.success;
        stateIcon = Icons.verified_user_rounded;
        break;
      case SeparationState.CAUTION:
        stateColor = WariColors.warning;
        stateIcon = Icons.warning_amber_rounded;
        break;
      case SeparationState.SEPARATED:
        stateColor = WariColors.crowdOrange;
        stateIcon = Icons.location_off_rounded;
        break;
      case SeparationState.CRITICAL:
        stateColor = WariColors.danger;
        stateIcon = Icons.error_rounded;
        break;
      case SeparationState.RETURNING:
        stateColor = WariColors.info;
        stateIcon = Icons.directions_walk_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: WariSpacing.xs),
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(
          color: state == SeparationState.SAFE ? WariColors.border : stateColor,
          width: state == SeparationState.SAFE ? 1.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Dindi Name & Network Sync Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: WariColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: WariColors.primary, size: 20),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dindi.name,
                        style: WariTypography.titleMedium.copyWith(fontSize: 16),
                      ),
                      Text(
                        'Code: ${dindi.joinCode} • ${dindiProvider.members.isNotEmpty ? dindiProvider.members.length : dindi.activeMemberCount} Varkaris',
                        style: WariTypography.bodySmall.copyWith(fontSize: 11, color: WariColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              _buildNetworkBadge(networkStatus),
            ],
          ),
          const SizedBox(height: WariSpacing.md),

          // Separation Status Banner
          Container(
            padding: const EdgeInsets.all(WariSpacing.sm),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(WariSpacing.md),
              border: Border.all(color: stateColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(stateIcon, color: stateColor, size: 28),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: stateColor,
                        ),
                      ),
                      Text(
                        'Distance to Dindi Leader / Group: ${VirtualDindiEngine.formatDistance(dindiProvider.distanceFromGroupMeters)} (${trend.displayName})',
                        style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.md),

          // Action Buttons: Open Live Map & Manage Dindi
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenMapPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state == SeparationState.SAFE ? WariColors.primary : stateColor,
                    padding: const EdgeInsets.symmetric(vertical: WariSpacing.xs),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: Text(
                    state == SeparationState.SAFE ? 'Open Live Map' : 'Navigate to Dindi',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              OutlinedButton.icon(
                onPressed: onDetailPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: WariSpacing.xs),
                ),
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Dindi Info', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotJoinedCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: WariSpacing.xs),
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(color: WariColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WariColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nature_people_rounded, color: WariColors.primary, size: 22),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Virtual Dindi & Separation Alert', style: WariTypography.titleMedium),
                    const Text(
                      'Travel digitally together with your Palkhi group & receive real-time separation warnings.',
                      style: TextStyle(fontSize: 11, color: WariColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onJoinPressed,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Join Dindi', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreatePressed,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Create Dindi', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkBadge(DindiNetworkStatus status) {
    Color bg;
    String label;
    switch (status) {
      case DindiNetworkStatus.LIVE:
        bg = WariColors.success;
        label = 'LIVE';
        break;
      case DindiNetworkStatus.SYNCING:
        bg = WariColors.warning;
        label = 'SYNCING';
        break;
      case DindiNetworkStatus.OFFLINE:
        bg = WariColors.danger;
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bg),
          ),
        ],
      ),
    );
  }
}
