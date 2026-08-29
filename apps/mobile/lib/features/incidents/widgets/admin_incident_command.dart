import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/incident_provider.dart';
import '../../../models/models_exports.dart';
import '../../../core/theme/wari_theme_exports.dart';

/// Live Incident Command Center widget on Executive Command Center Admin Dashboard.
/// Displays active incident stream with filter chips and interactive intervention command modal.
class AdminIncidentCommand extends StatefulWidget {
  const AdminIncidentCommand({super.key});

  @override
  State<AdminIncidentCommand> createState() => _AdminIncidentCommandState();
}

class _AdminIncidentCommandState extends State<AdminIncidentCommand> {
  String _selectedCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);
    final allIncidents = provider.allActiveIncidents;

    final filteredIncidents = _selectedCategory == 'ALL'
        ? allIncidents
        : allIncidents.where((i) => i.category.name == _selectedCategory).toList();

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
          // Header: Live Stream Title & Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.shield_rounded, color: WariColors.danger, size: 22),
                  SizedBox(width: WariSpacing.xs),
                  Text('Live Incident Command Queue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WariColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WariColors.danger),
                ),
                child: Text(
                  '${allIncidents.where((i) => i.isActive).length} Active',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WariColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          // Category Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Incidents'),
                _buildFilterChip('MEDICAL_EMERGENCY', 'Medical'),
                _buildFilterChip('STAMPEDE_RISK', 'Stampede'),
                _buildFilterChip('SECURITY_THREAT', 'Security'),
                _buildFilterChip('MISSING_PERSON', 'Missing'),
                _buildFilterChip('SANITATION_HAZARD', 'Sanitation'),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.sm),

          if (filteredIncidents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: WariSpacing.md),
              child: Center(
                child: Text(
                  '🟢 No active incidents matching filter.',
                  style: TextStyle(fontSize: 12, color: WariColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredIncidents.length > 5 ? 5 : filteredIncidents.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final inc = filteredIncidents[i];

                Color sevColor;
                switch (inc.severity) {
                  case IncidentSeverity.LOW: sevColor = WariColors.success; break;
                  case IncidentSeverity.MEDIUM: sevColor = WariColors.warning; break;
                  case IncidentSeverity.HIGH: sevColor = WariColors.crowdOrange; break;
                  case IncidentSeverity.CRITICAL: sevColor = WariColors.danger; break;
                }

                return InkWell(
                  onTap: () => _showIncidentDetailModal(context, provider, inc),
                  borderRadius: BorderRadius.circular(WariSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(WariSpacing.sm),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(WariSpacing.sm),
                      border: Border.all(color: sevColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.report_problem_rounded, color: sevColor, size: 18),
                                const SizedBox(width: 4),
                                Text(inc.category.displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: sevColor)),
                              ],
                            ),
                            Chip(
                              label: Text(inc.status.displayName, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: inc.isActive ? sevColor : WariColors.textMuted,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Reporter: ${inc.reporterName} (${inc.reporterRole})', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                        Text('Responder: ${inc.assignedVolunteerName ?? "Searching..."}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GPS: ${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 10, color: WariColors.textMuted)),
                            const Text('Command Panel →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WariColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : WariColors.textPrimary)),
        selected: isSelected,
        selectedColor: WariColors.primary,
        onSelected: (val) {
          if (val) setState(() => _selectedCategory = key);
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showIncidentDetailModal(BuildContext context, IncidentProvider provider, ThreatIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WariColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Incident #${incident.incidentId}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Text('Category: ${incident.category.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Severity: ${incident.severity.name}', style: const TextStyle(color: WariColors.danger, fontWeight: FontWeight.bold)),
              Text('Description: ${incident.description}'),
              Text('Reporter: ${incident.reporterName} (${incident.reporterRole})'),
              Text('GPS Location: ${incident.latitude}, ${incident.longitude}'),
              Text('Status: ${incident.status.displayName}'),
              Text('Assigned Responder: ${incident.assignedVolunteerName ?? "Unassigned"}'),
              const SizedBox(height: 16),
              const Text('⚡ Admin Interventions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.changePriority(incident.incidentId, IncidentSeverity.CRITICAL);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escalated incident to CRITICAL severity (Audit logged).')),
                        );
                      }
                    },
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Escalate to Critical'),
                    style: ElevatedButton.styleFrom(backgroundColor: WariColors.danger),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.reassignVolunteer(
                        incident.incidentId,
                        'vol_backup_01',
                        'Inspector Vikram Singh (Police & Security)',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reassigned responder to Inspector Vikram Singh (Audit logged).')),
                        );
                      }
                    },
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Reassign Responder'),
                    style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.resolveIncident(incident.incidentId, 'Resolved via Admin Command Center Override.');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incident marked RESOLVED by Admin (Audit logged).')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(backgroundColor: WariColors.success),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.cancelIncident(incident.incidentId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incident CANCELLED by Admin.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel Incident'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
