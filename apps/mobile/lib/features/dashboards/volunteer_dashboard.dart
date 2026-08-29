import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';
import '../incidents/volunteer_response_queue_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  String _volunteerStatus = 'AVAILABLE';

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, sosProvider, _) {
          final incidents = sosProvider.incidents;
          final activeSos = incidents.where((s) => s.status == SOSStatus.CREATED || s.status == SOSStatus.ACKNOWLEDGED).toList();

          return Scaffold(
            backgroundColor: WariColors.background,
            body: Column(
              children: [
                RoleDashboardHeader(
                  role: UserRole.VOLUNTEER,
                  subtitle: 'Respond to nearby emergencies and help requests',
                  badgeText: 'STATUS: $_volunteerStatus',
                  badgeColor: _volunteerStatus == 'AVAILABLE' ? WariColors.success : WariColors.warning,
                  actionWidget: Row(
                    children: ['AVAILABLE', 'BUSY', 'OFFLINE'].map((status) {
                      final isSel = _volunteerStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          selected: isSel,
                          label: Text(status, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selectedColor: status == 'AVAILABLE' ? WariColors.successLight : WariColors.warningLight,
                          onSelected: (_) {
                            setState(() {
                              _volunteerStatus = status;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(WariSpacing.base),
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerResponseQueueScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WariColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.support_agent_rounded),
                        label: const Text('OPEN LIVE RESPONSE QUEUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(height: WariSpacing.base),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: WariSpacing.sm,
                        crossAxisSpacing: WariSpacing.sm,
                        childAspectRatio: 1.6,
                        children: [
                          MetricCard(label: 'Active SOS', value: '${activeSos.length}', icon: Icons.emergency, color: WariColors.danger),
                          const MetricCard(label: 'Help Requests', value: '4', icon: Icons.handshake, color: WariColors.primary),
                          const MetricCard(label: 'Missing Cases', value: '2', icon: Icons.person_search, color: WariColors.accent),
                          const MetricCard(label: 'Community Updates', value: '8', icon: Icons.campaign, color: WariColors.success),
                        ],
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('🆘 Nearby Active SOS Alerts', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      if (activeSos.isEmpty)
                        WariCard(child: Text('No active SOS alerts nearby. You are on standby.', style: WariTypography.bodySmall))
                      else
                        Column(
                          children: activeSos.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                              child: WariCard(
                                borderColor: WariColors.danger.withValues(alpha: 0.3),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(s.category.displayName, style: WariTypography.titleSmall.copyWith(color: WariColors.danger)),
                                        WariStatusChip(label: s.status.displayName, color: WariColors.danger, dense: true),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(s.description ?? 'Emergency assistance needed', style: WariTypography.bodySmall),
                                    const SizedBox(height: WariSpacing.xs),
                                    WariPrimaryButton(
                                      label: 'Accept & Respond',
                                      dense: true,
                                      backgroundColor: WariColors.danger,
                                      onPressed: () => sosProvider.resolveActiveSOS(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: WariSpacing.base),
                      Text('📜 Resolved SOS Response History', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),
                      WariCard(
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                radius: 14,
                                backgroundColor: WariColors.successLight,
                                child: Icon(Icons.check, size: 16, color: WariColors.success),
                              ),
                              title: Text('Medical Aid at Sector 4', style: WariTypography.labelMedium),
                              subtitle: Text('Resolved by Volunteer Team • 45m ago', style: WariTypography.caption),
                              trailing: const WariStatusChip(label: 'RESOLVED', color: WariColors.success, dense: true),
                            ),
                            const Divider(height: 8),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                radius: 14,
                                backgroundColor: WariColors.successLight,
                                child: Icon(Icons.check, size: 16, color: WariColors.success),
                              ),
                              title: Text('Lost Pilgrim Reunification', style: WariTypography.labelMedium),
                              subtitle: Text('Resolved by Volunteer Team • 2h ago', style: WariTypography.caption),
                              trailing: const WariStatusChip(label: 'RESOLVED', color: WariColors.success, dense: true),
                            ),
                          ],
                        ),
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
