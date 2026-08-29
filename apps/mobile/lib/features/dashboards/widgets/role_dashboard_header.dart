import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

/// Standard operational dashboard header banner.
class RoleDashboardHeader extends StatelessWidget {
  const RoleDashboardHeader({
    super.key,
    required this.role,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.actionWidget,
  });

  final UserRole role;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? actionWidget;

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);

    return Container(
      padding: const EdgeInsets.all(WariSpacing.base),
      decoration: BoxDecoration(
        color: WariColors.surface,
        border: Border(bottom: BorderSide(color: WariColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(_getRoleIcon(role), color: color, size: 24),
                    const SizedBox(width: WariSpacing.xs),
                    Flexible(
                      child: Text(
                        role.displayName,
                        style: WariTypography.headlineSmall.copyWith(color: WariColors.slate900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              if (badgeText != null)
                WariStatusChip(
                  label: badgeText!,
                  color: badgeColor ?? color,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: WariTypography.bodySmall),
          if (actionWidget != null) ...[
            const SizedBox(height: WariSpacing.sm),
            actionWidget!,
          ],
        ],
      ),
    );
  }

  static IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.VARKARI: return Icons.temple_hindu;
      case UserRole.DINDI_LEADER: return Icons.groups;
      case UserRole.VOLUNTEER: return Icons.handshake;
      case UserRole.MEDICAL_TEAM: return Icons.local_hospital;
      case UserRole.POLICE: return Icons.local_police;
      case UserRole.NGO: return Icons.volunteer_activism;
      case UserRole.SERVICE_PROVIDER: return Icons.restaurant;
      case UserRole.CLEANER: return Icons.cleaning_services;
      case UserRole.ADMIN: return Icons.admin_panel_settings;
    }
  }

  static Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.VARKARI: return WariColors.primary;
      case UserRole.DINDI_LEADER: return WariColors.primaryDark;
      case UserRole.VOLUNTEER: return WariColors.primary;
      case UserRole.MEDICAL_TEAM: return WariColors.danger;
      case UserRole.POLICE: return WariColors.info;
      case UserRole.NGO: return WariColors.success;
      case UserRole.SERVICE_PROVIDER: return WariColors.foodColor;
      case UserRole.CLEANER: return WariColors.toiletColor;
      case UserRole.ADMIN: return WariColors.accent;
    }
  }

}
