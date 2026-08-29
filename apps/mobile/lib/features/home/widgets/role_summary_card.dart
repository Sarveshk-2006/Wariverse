import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../navigation/app_routes.dart';

/// Contextual role operational banner on Home.
/// Adapts metrics and guidance based on active UserRole.
class RoleSummaryCard extends StatelessWidget {
  const RoleSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final role = userProvider.currentRole;
    final analytics = homeProvider.adminAnalytics;

    return WariAccentCard(
      accentColor: _getRoleColor(role),
      onTap: () => Navigator.pushNamed(context, AppRoutes.roleDashboard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getRoleIcon(role), size: 18, color: _getRoleColor(role)),
                  const SizedBox(width: WariSpacing.xs),
                  Text(
                    '${role.displayName} Workspace',
                    style: WariTypography.titleMedium.copyWith(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'Open Ops →',
                style: WariTypography.labelSmall.copyWith(
                  color: _getRoleColor(role),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Text(
            _getRoleSummaryText(role, analytics),
            style: WariTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  static Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.VARKARI:          return WariColors.primary;
      case UserRole.DINDI_LEADER:     return WariColors.primaryDark;
      case UserRole.VOLUNTEER:        return WariColors.success;
      case UserRole.MEDICAL_TEAM:     return WariColors.danger;
      case UserRole.POLICE:           return WariColors.info;
      case UserRole.NGO:              return WariColors.shelterColor;
      case UserRole.SERVICE_PROVIDER: return WariColors.foodColor;
      case UserRole.CLEANER:          return WariColors.toiletColor;
      case UserRole.ADMIN:            return WariColors.accent;
    }
  }

  static IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.VARKARI:          return Icons.temple_hindu;
      case UserRole.DINDI_LEADER:     return Icons.groups;
      case UserRole.VOLUNTEER:        return Icons.handshake;
      case UserRole.MEDICAL_TEAM:     return Icons.local_hospital;
      case UserRole.POLICE:           return Icons.local_police;
      case UserRole.NGO:              return Icons.volunteer_activism;
      case UserRole.SERVICE_PROVIDER: return Icons.restaurant;
      case UserRole.CLEANER:          return Icons.cleaning_services;
      case UserRole.ADMIN:            return Icons.admin_panel_settings;
    }
  }

  static String _getRoleSummaryText(UserRole role, AdminAnalytics? analytics) {
    switch (role) {
      case UserRole.VARKARI:
        return 'Pilgrimage Route: Solapur Road clear. Stay hydrated and check nearest Annadan.';
      case UserRole.DINDI_LEADER:
        return 'Dindi No. 12 Command: 142 registered members active. Live GPS beacon broadcasting.';
      case UserRole.VOLUNTEER:
        return 'Ghat Zone A: 14 tasks completed. 2 active SOS incidents nearby requiring support.';
      case UserRole.MEDICAL_TEAM:
        return 'Medical Command: 8 active SOS requests. Government Hospital ambulance ready.';
      case UserRole.POLICE:
        return 'Traffic & Crowd: Alandi route heavy crowd. 450,000 active pilgrims near Wakhari.';
      case UserRole.NGO:
        return 'Logistics Seva: 18,500 water pouches remaining. 50,000 meals distributed today.';
      case UserRole.SERVICE_PROVIDER:
        return 'Annadan Hub: 14,200 / 20,000 meals served. Queue wait time: 10 minutes.';
      case UserRole.CLEANER:
        return 'Sanitation Log: Sanitation Block B clean. 1 toilet block pending inspection.';
      case UserRole.ADMIN:
        return 'Command Center: 1.4M estimated total pilgrims. ${analytics?.crowdAlerts ?? 3} active crowd alerts.';
    }
  }

}
