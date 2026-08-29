import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/incident_provider.dart';
import '../../models/threat_incident_model.dart';
import '../../core/theme/wari_theme_exports.dart';

class VolunteerResponseQueueScreen extends StatefulWidget {
  const VolunteerResponseQueueScreen({super.key});

  @override
  State<VolunteerResponseQueueScreen> createState() => _VolunteerResponseQueueScreenState();
}

class _VolunteerResponseQueueScreenState extends State<VolunteerResponseQueueScreen> {
  final _resolutionNotesController = TextEditingController();

  Future<void> _launchNavigation(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showResolveDialog(BuildContext context, IncidentProvider provider, String incidentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter resolution notes / assistance summary:'),
            const SizedBox(height: WariSpacing.xs),
            TextField(
              controller: _resolutionNotesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Provided medical first aid, Varkari is safe and reunited.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final notes = _resolutionNotesController.text.trim().isEmpty
                  ? 'Resolved by responder.'
                  : _resolutionNotesController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              _resolutionNotesController.clear();
              Navigator.pop(ctx);
              await provider.resolveIncident(incidentId, notes);
              messenger.showSnackBar(
                const SnackBar(content: Text('✅ Incident marked as RESOLVED.')),
              );
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);
    final assigned = provider.assignedIncidents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Response Queue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(WariSpacing.md),
                border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: WariColors.primary, size: 28),
                  const SizedBox(width: WariSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Volunteer Emergency Dispatch Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.primary)),
                        Text('Assigned incidents update automatically in realtime. Accept, start live navigation, and mark arrived/resolved.', style: TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.md),

            if (assigned.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text('🟢 No incidents currently assigned to your response queue.', style: TextStyle(color: WariColors.textMuted)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assigned.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: WariSpacing.md),
                itemBuilder: (ctx, i) {
                  final inc = assigned[i];

                  Color sevColor;
                  switch (inc.severity) {
                    case IncidentSeverity.LOW: sevColor = WariColors.success; break;
                    case IncidentSeverity.MEDIUM: sevColor = WariColors.warning; break;
                    case IncidentSeverity.HIGH: sevColor = WariColors.crowdOrange; break;
                    case IncidentSeverity.CRITICAL: sevColor = WariColors.danger; break;
                  }

                  return Container(
                    padding: const EdgeInsets.all(WariSpacing.md),
                    decoration: BoxDecoration(
                      color: WariColors.surface,
                      borderRadius: BorderRadius.circular(WariSpacing.md),
                      border: Border.all(color: sevColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inc.category.displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sevColor)),
                            Chip(
                              label: Text(inc.status.displayName, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: sevColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Reporter: ${inc.reporterName} (${inc.reporterPhone})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Details: ${inc.description}', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                        Text('Location GPS: ${inc.latitude.toStringAsFixed(5)}, ${inc.longitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 11, color: WariColors.textMuted)),
                        const SizedBox(height: WariSpacing.md),

                        // Action Controls based on status
                        if (inc.status == IncidentStatus.ASSIGNED) ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await provider.acceptIncident(inc.incidentId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Accepted incident response!')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: WariColors.success),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('ACCEPT INCIDENT ASSIGNMENT'),
                          ),
                        ] else if (inc.status == IncidentStatus.ACCEPTED || inc.status == IncidentStatus.EN_ROUTE || inc.status == IncidentStatus.ARRIVED) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchNavigation(inc.latitude, inc.longitude),
                                  icon: const Icon(Icons.navigation_rounded, size: 16),
                                  label: const Text('Navigate (Maps)', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (inc.status == IncidentStatus.ACCEPTED)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => provider.setEnRoute(inc.incidentId),
                                    icon: const Icon(Icons.directions_walk_rounded, size: 16),
                                    label: const Text('Set En Route', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              if (inc.status == IncidentStatus.EN_ROUTE)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => provider.markArrived(inc.incidentId),
                                    icon: const Icon(Icons.location_on_rounded, size: 16),
                                    label: const Text('Mark Arrived', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                onPressed: () => _showResolveDialog(context, provider, inc.incidentId),
                                style: ElevatedButton.styleFrom(backgroundColor: WariColors.success),
                                icon: const Icon(Icons.done_all_rounded, size: 16),
                                label: const Text('Resolve', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
