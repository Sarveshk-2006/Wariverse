import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';

class MedicalDashboard extends StatelessWidget {
  const MedicalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SosProvider>(
      builder: (context, sosProvider, _) {
          final incidents = sosProvider.incidents;
          final medicalSos = incidents.where((s) => s.category == SOSCategory.MEDICAL || s.category == SOSCategory.ACCIDENT || s.category == SOSCategory.DEHYDRATION).toList();

          return Scaffold(
            backgroundColor: WariColors.background,
            body: Column(
              children: [
                RoleDashboardHeader(
                  role: UserRole.MEDICAL_TEAM,
                  subtitle: 'Emergency medical queue, triage & camp coordination',
                  badgeText: '${medicalSos.length} MEDICAL CASES',
                  badgeColor: WariColors.danger,
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
                          MetricCard(label: 'Emergency Queue', value: '${medicalSos.length}', icon: Icons.local_hospital, color: WariColors.danger),
                          const MetricCard(label: 'Assigned Cases', value: '2', icon: Icons.assignment_ind, color: WariColors.warning),
                          const MetricCard(label: 'Resolved Today', value: '14', icon: Icons.check_circle, color: WariColors.success),
                          const MetricCard(label: 'Active Camps', value: '6', icon: Icons.cabin, color: WariColors.info),
                        ],
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('🚨 Medical Triage Queue', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      if (medicalSos.isEmpty)
                        WariCard(child: Text('✅ No active medical emergency cases in queue.', style: WariTypography.bodySmall))
                      else
                        Column(
                          children: medicalSos.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                              child: WariCard(
                                borderColor: WariColors.danger.withValues(alpha: 0.4),
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
                                    Text(s.description ?? 'Medical aid required', style: WariTypography.bodySmall),
                                    if (s.bloodGroup != null)
                                      Text('Blood Group: ${s.bloodGroup}', style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: WariSpacing.xs),
                                    WariPrimaryButton(
                                      label: 'Accept Medical Case',
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
