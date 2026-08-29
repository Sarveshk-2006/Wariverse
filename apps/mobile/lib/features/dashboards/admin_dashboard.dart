import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, sosProvider, _) => _buildAdminContent(context, sosProvider),
    );
  }

  Widget _buildAdminContent(BuildContext context, SosProvider sosProvider) {
    final incidents = sosProvider.incidents;

    return Scaffold(
      backgroundColor: WariColors.background,
            body: Column(
              children: [
                const RoleDashboardHeader(
                  role: UserRole.ADMIN,
                  subtitle: 'Command Center central operational overview & live feeds',
                  badgeText: 'COMMAND CENTER ADMIN',
                  badgeColor: WariColors.accent,
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
                        childAspectRatio: 1.5,
                        children: [
                          const MetricCard(label: 'Active Varkaris', value: '250,000', icon: Icons.temple_hindu, color: WariColors.primary),
                          MetricCard(label: 'Active SOS', value: '${incidents.length}', icon: Icons.emergency, color: WariColors.danger),
                          const MetricCard(label: 'Red Crowd Zones', value: '1', icon: Icons.warning, color: WariColors.crowdRed),
                          const MetricCard(label: 'Active Volunteers', value: '45', icon: Icons.handshake, color: WariColors.success),
                          const MetricCard(label: 'Food Centres', value: '6/6', icon: Icons.restaurant, color: WariColors.foodColor),
                          const MetricCard(label: 'Water Points', value: '5/5', icon: Icons.water_drop, color: WariColors.waterColor),
                          const MetricCard(label: 'Missing Cases', value: '2', icon: Icons.person_search, color: WariColors.accent),
                          const MetricCard(label: 'Pilgrims (Est.)', value: '500,000', icon: Icons.insights, color: WariColors.info, subtext: 'DEMO ESTIMATE'),
                        ],
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('⚡ Live Command Center Incident Stream', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      if (incidents.isEmpty)
                        WariCard(child: Text('No active incidents reported in stream.', style: WariTypography.bodySmall))
                      else
                        Column(
                          children: incidents.take(5).map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                              child: WariCard(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.category.displayName, style: WariTypography.titleSmall),
                                          Text(
                                            'Ref: ${s.id} · ${s.description ?? "Active emergency"}',
                                            style: WariTypography.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: WariSpacing.xs),
                                    WariStatusChip(label: s.status.displayName, color: WariColors.danger, dense: true),
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
  }
}
