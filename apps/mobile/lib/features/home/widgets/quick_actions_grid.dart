import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../navigation/app_routes.dart';

/// Quick actions matrix widget matching the web mobile navigation grid.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Instant access to critical pilgrimage tools',
        ),
        const SizedBox(height: WariSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: WariSpacing.sm,
          crossAxisSpacing: WariSpacing.sm,
          childAspectRatio: 0.82,
          children: [
            _QuickActionTile(
              icon: Icons.groups,
              label: 'My Dindi',
              color: WariColors.primaryDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.dindi),
            ),
            _QuickActionTile(
              icon: Icons.map,
              label: 'Live Map',
              color: WariColors.info,
              onTap: () => Navigator.pushNamed(context, AppRoutes.map),
            ),
            _QuickActionTile(
              icon: Icons.emergency,
              label: 'Smart SOS',
              color: WariColors.danger,
              isEmergency: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.sosStatus, arguments: 'new-sos'),
            ),
            _QuickActionTile(
              icon: Icons.person_search,
              label: 'Lost & Found',
              color: WariColors.accent,
              onTap: () => Navigator.pushNamed(context, AppRoutes.lostFound),
            ),
            _QuickActionTile(
              icon: Icons.campaign,
              label: 'Community',
              color: WariColors.success,
              onTap: () => Navigator.pushNamed(context, AppRoutes.community),
            ),
            _QuickActionTile(
              icon: Icons.restaurant,
              label: 'Annadan',
              color: WariColors.foodColor,
              onTap: () => Navigator.pushNamed(context, AppRoutes.services),
            ),
            _QuickActionTile(
              icon: Icons.water_drop,
              label: 'Water',
              color: WariColors.waterColor,
              onTap: () => Navigator.pushNamed(context, AppRoutes.services),
            ),
            _QuickActionTile(
              icon: Icons.local_hospital,
              label: 'Medical',
              color: WariColors.medicalColor,
              onTap: () => Navigator.pushNamed(context, AppRoutes.services),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEmergency ? WariColors.dangerLight : WariColors.surface,
      borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
            border: Border.all(
              color: isEmergency ? WariColors.danger : WariColors.border,
              width: isEmergency ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: WariSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(WariSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: WariTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isEmergency ? WariColors.danger : WariColors.textPrimary,
                  fontWeight: isEmergency ? FontWeight.bold : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
