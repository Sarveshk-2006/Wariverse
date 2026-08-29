import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/ngo_distribution_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';
import '../incidents/widgets/admin_incident_command.dart';
import '../../services/firestore_seeder_service.dart';

/// Central Executive Command & Control Center Dashboard for Admin.
/// Provides real-time telemetry, emergency response command, NGO oversight, Dindi monitoring,
/// Sanitation dispatches, system health badges, and capability approval controls.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isSeeding = false;

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    final success = await FirestoreSeederService.seedAllDemoData();
    if (mounted) {
      setState(() => _isSeeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✓ Live demo dataset seeded to Cloud Firestore successfully!'
                : 'Failed to seed demo dataset. Check console logs.',
          ),
          backgroundColor: success ? WariColors.success : WariColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<SosProvider, IncidentProvider, NgoDistributionProvider, VirtualDindiProvider>(
      builder: (context, sosProvider, incidentProvider, ngoProvider, dindiProvider, _) {
        return _buildAdminContent(context, sosProvider, incidentProvider, ngoProvider, dindiProvider);
      },
    );
  }

  Widget _buildAdminContent(
    BuildContext context,
    SosProvider sosProvider,
    IncidentProvider incidentProvider,
    NgoDistributionProvider ngoProvider,
    VirtualDindiProvider dindiProvider,
  ) {
    final activeIncidents = incidentProvider.allActiveIncidents;
    final sosIncidents = sosProvider.incidents;
    final criticalCount = activeIncidents.where((i) => i.severity == IncidentSeverity.CRITICAL).length;
    final ngoDeployments = ngoProvider.activeDistributions;
    final activeDindi = dindiProvider.activeDindi;
    final auditLogs = incidentProvider.auditLogs;

    return Scaffold(
      backgroundColor: WariColors.background,
      body: Column(
        children: [
          const RoleDashboardHeader(
            role: UserRole.ADMIN,
            subtitle: 'Real-time Command & Control Center — System Telemetry',
            badgeText: 'COMMAND CENTER ADMIN',
            badgeColor: WariColors.accent,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(WariSpacing.base),
              children: [
                WariCard(
                  borderColor: WariColors.primary.withValues(alpha: 0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Populate Live Firestore Demo Data',
                              style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark),
                            ),
                            Text(
                              'Seeds authentic Dindis, Varkaris, Incidents, NGO Aid & Services into Cloud Firestore.',
                              style: WariTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      WariPrimaryButton(
                        label: _isSeeding ? 'Seeding...' : 'Seed Now',
                        onPressed: _isSeeding ? null : _seedDemoData,
                        fullWidth: false,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.base),
                // 1. Real-Time Command KPIs Grid
                Text('📊 Real-Time Operations Telemetry', style: WariTypography.titleSmall),
                const SizedBox(height: WariSpacing.xs),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: WariSpacing.sm,
                  crossAxisSpacing: WariSpacing.sm,
                  childAspectRatio: 1.5,
                  children: [
                    MetricCard(
                      label: 'Active SOS',
                      value: '${sosIncidents.length}',
                      icon: Icons.emergency,
                      color: WariColors.danger,
                    ),
                    MetricCard(
                      label: 'Active Threats',
                      value: '${activeIncidents.where((i) => i.isActive).length}',
                      icon: Icons.warning_amber_rounded,
                      color: WariColors.crowdOrange,
                    ),
                    MetricCard(
                      label: 'Critical Incidents',
                      value: '$criticalCount',
                      icon: Icons.report_problem,
                      color: WariColors.danger,
                    ),
                    const MetricCard(
                      label: 'Volunteers Online',
                      value: '48',
                      icon: Icons.handshake,
                      color: WariColors.success,
                    ),
                    MetricCard(
                      label: 'Active Dindis',
                      value: activeDindi != null ? '1 Active' : '0 Active',
                      icon: Icons.groups,
                      color: WariColors.primary,
                    ),
                    MetricCard(
                      label: 'Separated Varkaris',
                      value: '${dindiProvider.separatedMembers.length}',
                      icon: Icons.person_search,
                      color: dindiProvider.hasSeparationAlert ? WariColors.danger : WariColors.success,
                    ),
                    MetricCard(
                      label: 'NGO Deployments',
                      value: '${ngoDeployments.length}',
                      icon: Icons.volunteer_activism,
                      color: WariColors.accent,
                    ),
                    MetricCard(
                      label: 'System Status',
                      value: incidentProvider.networkStatus.name,
                      icon: Icons.wifi_tethering,
                      color: incidentProvider.networkStatus == IncidentNetworkStatus.LIVE
                          ? WariColors.success
                          : WariColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.base),

                // 2. Live Emergency Command Feed
                Text('📡 Live Emergency Command Feed', style: WariTypography.titleSmall),
                const SizedBox(height: WariSpacing.xs),
                _buildLiveFeedCard(auditLogs),
                const SizedBox(height: WariSpacing.base),

                // 3. Incident Command Queue Widget
                const AdminIncidentCommand(),
                const SizedBox(height: WariSpacing.base),

                // 4. Virtual Dindi Telemetry Card
                _buildDindiTelemetryCard(dindiProvider),
                const SizedBox(height: WariSpacing.base),

                // 5. Capability & Role Approval Queue
                _buildCapabilityApprovalQueueCard(context),
                const SizedBox(height: WariSpacing.base),

                // 6. NGO Resources Operations & Aid Oversight
                _buildNgoOversightCard(context, ngoDeployments),
                const SizedBox(height: WariSpacing.base),

                // 7. System Health & Infrastructure Monitor
                _buildSystemHealthCard(incidentProvider),
                const SizedBox(height: WariSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveFeedCard(List<AuditLog> auditLogs) {
    if (auditLogs.isEmpty) {
      return WariCard(
        child: Row(
          children: const [
            Icon(Icons.history_toggle_off, color: WariColors.textMuted),
            SizedBox(width: 8),
            Text('No operational audit events recorded yet.', style: TextStyle(fontSize: 12, color: WariColors.textMuted)),
          ],
        ),
      );
    }

    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Event Stream', style: WariTypography.titleSmall),
              const WariStatusChip(label: 'REALTIME STREAM', color: WariColors.success, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auditLogs.length > 4 ? 4 : auditLogs.length,
            itemBuilder: (ctx, idx) {
              final log = auditLogs[idx];
              final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(timeStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WariColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${log.action} • ${log.target}',
                        style: const TextStyle(fontSize: 11, color: WariColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDindiTelemetryCard(VirtualDindiProvider provider) {
    final dindi = provider.activeDindi;

    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🚩 Virtual Dindi Telemetry & Separation', style: WariTypography.titleSmall),
              WariStatusChip(
                label: provider.hasSeparationAlert ? 'SEPARATION ALERT' : 'NORMAL',
                color: provider.hasSeparationAlert ? WariColors.danger : WariColors.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (dindi == null)
            const Text('No active Virtual Dindi currently tracked by Command Center.', style: TextStyle(fontSize: 11, color: WariColors.textSecondary))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dindi: ${dindi.name} (Code: ${dindi.joinCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Leader: ${dindi.leaderName} • Total Members: ${provider.members.length}'),
                Text('Safe: ${provider.safeMembers.length} • Caution: ${provider.cautionMembers.length} • Separated: ${provider.separatedMembers.length}'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCapabilityApprovalQueueCard(BuildContext context) {
    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🛡️ Capability & Role Approval Queue', style: WariTypography.titleSmall),
          const SizedBox(height: 4),
          Text('Approve or reject secondary capability requests from registered Varkaris.', style: WariTypography.bodySmall),
          const SizedBox(height: WariSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Volunteer Request — Ramesh Pawar'),
            subtitle: const Text('Requested: Volunteer Field Responder Capability'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: WariColors.success),
                  onPressed: () {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.adminSetCapabilityStatus('varkari-10', 'volunteer', 'APPROVED');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Volunteer capability APPROVED (Audit logged).')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: WariColors.danger),
                  onPressed: () {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.adminSetCapabilityStatus('varkari-10', 'volunteer', 'REJECTED');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Volunteer capability REJECTED (Audit logged).')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNgoOversightCard(BuildContext context, List<ResourceDistribution> deployments) {
    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📦 NGO Resource Deployments', style: WariTypography.titleSmall),
              const WariStatusChip(label: 'REALTIME OVERSIGHT', color: WariColors.primary, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text('Global command center monitoring for food, water, medical camps & shelter aid.', style: WariTypography.bodySmall),
          const SizedBox(height: WariSpacing.sm),
          if (deployments.isEmpty)
            const Text('No active NGO resource deployments published.', style: TextStyle(fontSize: 11, color: WariColors.textMuted))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deployments.length > 3 ? 3 : deployments.length,
              itemBuilder: (ctx, idx) {
                final d = deployments[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(d.category.icon, color: d.category.color),
                  title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${d.ngoName} · ${d.remainingQuantity}/${d.quantity} ${d.unit} remaining'),
                  trailing: WariStatusChip(label: d.computedAvailabilityStatus, color: WariColors.success, dense: true),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard(IncidentProvider incidentProvider) {
    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🖥️ System Health & Infrastructure Services', style: WariTypography.titleSmall),
          const SizedBox(height: WariSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceBadge('Firebase Auth', 'ONLINE', WariColors.success),
              _buildServiceBadge('Cloud Firestore', 'LIVE STREAM', WariColors.success),
              _buildServiceBadge('GPS Tracking', 'ACTIVE', WariColors.success),
              _buildServiceBadge('OneSignal Push', 'CONFIGURED', WariColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBadge(String name, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Column(
        children: [
          Text(name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
