import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';

class PoliceDashboard extends StatelessWidget {
  const PoliceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, sosProvider, _) {
          final incidents = sosProvider.incidents;

          return Scaffold(
            backgroundColor: WariColors.background,
            body: Column(
              children: [
                RoleDashboardHeader(
                  role: UserRole.POLICE,
                  subtitle: 'Security, crowd safety & emergency response monitoring',
                  badgeText: '${incidents.length} INCIDENTS',
                  badgeColor: WariColors.info,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(WariSpacing.base),
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: WariSpacing.sm,
                        crossAxisSpacing: WariSpacing.sm,
                        childAspectRatio: 1.6,
                        children: [
                          MetricCard(label: 'Active Incidents', value: '${incidents.length}', icon: Icons.emergency, color: WariColors.danger),
                          const MetricCard(label: 'Missing Persons', value: '3', icon: Icons.person_search, color: WariColors.accent),
                          const MetricCard(label: 'Red Crowd Zones', value: '1', icon: Icons.warning, color: WariColors.crowdRed),
                          const MetricCard(label: 'Orange Zones', value: '2', icon: Icons.error_outline, color: WariColors.crowdOrange),
                        ],
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('🔴 Critical Crowd Risk Zones', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      WariCard(
                        borderColor: WariColors.crowdRed,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Vitthal Mandir Ghat Zone', style: WariTypography.titleSmall),
                                const WariStatusChip(label: 'CRITICAL DENSITY', color: WariColors.crowdRed, dense: true),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Estimated Count: 45,000 pilgrims · Density: 92%', style: WariTypography.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('🚔 Active SOS Incidents', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      if (incidents.isEmpty)
                        WariCard(child: Text('No active police incidents recorded.', style: WariTypography.bodySmall))
                      else
                        Column(
                          children: incidents.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                              child: WariCard(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.category.displayName, style: WariTypography.titleSmall),
                                        Text(s.description ?? 'No details', style: WariTypography.bodySmall),
                                      ],
                                    ),
                                    WariStatusChip(label: s.status.displayName, color: WariColors.info, dense: true),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
    );
  }
}
