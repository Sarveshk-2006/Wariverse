import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/sos_provider.dart';
import '../../../providers/user_provider.dart';

/// Operational incident list view for Police, Medical, Volunteer, NGO, Admin roles.
class SosIncidentListView extends StatelessWidget {
  const SosIncidentListView({super.key});

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final activeRole = userProvider.currentRole;

    if (sosProvider.isLoading) {
      return const WariLoadingIndicator(message: 'Loading active emergency incidents...');
    }

    final incidents = sosProvider.incidents;

    if (incidents.isEmpty) {
      return WariEmptyState(
        icon: Icons.shield,
        title: 'No Active Emergency Incidents',
        subtitle: 'All routes and zones are currently operating safely.',
        actionLabel: 'Refresh',
        onAction: () => sosProvider.loadIncidents(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final inc = incidents[index];
        final isCritical = inc.category == SOSCategory.ACCIDENT || inc.category == SOSCategory.WOMEN_SAFETY;
        final hasDesc = inc.description != null && inc.description!.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariCard(
            borderColor: isCritical ? WariColors.danger.withValues(alpha: 0.5) : WariColors.border,
            borderWidth: isCritical ? 1.5 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_getCategoryEmoji(inc.category), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: WariSpacing.xs),
                        Text(
                          inc.category.displayName,
                          style: WariTypography.titleSmall.copyWith(
                            color: isCritical ? WariColors.danger : WariColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    WariStatusChip(
                      label: inc.status.displayName,
                      color: _getStatusColor(inc.status),
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  hasDesc ? inc.description! : 'No description provided',
                  style: WariTypography.bodySmall,
                ),
                const SizedBox(height: WariSpacing.xs),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: WariColors.slate500),
                    const SizedBox(width: 4),
                    Text(
                      '${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)}',
                      style: WariTypography.caption,
                    ),
                    if (inc.responderDistanceM != null) ...[
                      const SizedBox(width: WariSpacing.sm),
                      Text('· ${inc.responderDistanceM}m away', style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                const SizedBox(height: WariSpacing.sm),

                // Role-Specific Actions
                if (activeRole == UserRole.POLICE || activeRole == UserRole.MEDICAL_TEAM || activeRole == UserRole.VOLUNTEER || activeRole == UserRole.ADMIN)
                  Row(
                    children: [
                      if (inc.status == SOSStatus.CREATED)
                        Expanded(
                          child: WariPrimaryButton(
                            label: 'Acknowledge',
                            dense: true,
                            onPressed: () => sosProvider.resolveActiveSOS(),
                          ),
                        ),
                      if (inc.status == SOSStatus.ACKNOWLEDGED || inc.status == SOSStatus.VOLUNTEER_ASSIGNED) ...[
                        Expanded(
                          child: WariPrimaryButton(
                            label: 'Resolve Incident',
                            dense: true,
                            backgroundColor: WariColors.success,
                            onPressed: () => sosProvider.resolveActiveSOS(),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getCategoryEmoji(SOSCategory cat) {
    switch (cat) {
      case SOSCategory.MEDICAL: return '🏥';
      case SOSCategory.ACCIDENT: return '🚨';
      case SOSCategory.LOST: return '👤';
      case SOSCategory.WOMEN_SAFETY: return '🆘';
      case SOSCategory.CHILD: return '👶';
      case SOSCategory.DEHYDRATION: return '💧';
      case SOSCategory.FATIGUE: return '😓';
      case SOSCategory.OTHER: return '❓';
    }
  }

  static Color _getStatusColor(SOSStatus status) {
    switch (status) {
      case SOSStatus.CREATED:            return WariColors.danger;
      case SOSStatus.ACKNOWLEDGED:       return WariColors.warning;
      case SOSStatus.VOLUNTEER_ASSIGNED: return WariColors.info;
      case SOSStatus.MEDICAL_ASSIGNED:   return WariColors.info;
      case SOSStatus.IN_PROGRESS:        return WariColors.primary;
      case SOSStatus.RESOLVED:           return WariColors.success;
      case SOSStatus.CANCELLED:          return WariColors.slate500;
    }
  }
}
