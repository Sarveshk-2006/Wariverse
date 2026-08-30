import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/incident_provider.dart';
import '../../models/threat_incident_model.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';

/// "ACTIVE TASK" Tab — Volunteer Incident Response Workflow Screen.
/// Displays ONLY the active incident currently being handled by the logged-in volunteer.
class VolunteerActiveTaskScreen extends StatefulWidget {
  const VolunteerActiveTaskScreen({super.key});

  @override
  State<VolunteerActiveTaskScreen> createState() => _VolunteerActiveTaskScreenState();
}

class _VolunteerActiveTaskScreenState extends State<VolunteerActiveTaskScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
        title: const Text('Complete & Resolve Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter assistance resolution notes:'),
            const SizedBox(height: WariSpacing.xs),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Provided medical assistance and hydrated Varkari. Fully safe.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final notes = _notesController.text.trim().isEmpty ? 'Resolved by responder.' : _notesController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              _notesController.clear();
              Navigator.pop(ctx);

              await provider.resolveIncident(incidentId, notes);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✅ Incident marked as RESOLVED and moved to History.'),
                  backgroundColor: WariColors.success,
                ),
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
    final active = provider.myActiveIncident;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Response Task'),
      ),
      body: active == null
          ? const Center(
              child: WariEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'You\'re All Clear!',
                subtitle: 'No active emergency response task assigned to you right now.',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Status Progress Indicator
                  Container(
                    padding: const EdgeInsets.all(WariSpacing.base),
                    decoration: BoxDecoration(
                      color: WariColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                      border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Active Dispatch Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            WariStatusChip(label: active.status.displayName, color: WariColors.primary, dense: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStepBadge('1. Accepted', isCompleted: active.status.index >= IncidentStatus.ACCEPTED.index),
                            const Icon(Icons.arrow_forward, size: 14, color: WariColors.textMuted),
                            _buildStepBadge('2. En Route', isCompleted: active.status.index >= IncidentStatus.EN_ROUTE.index),
                            const Icon(Icons.arrow_forward, size: 14, color: WariColors.textMuted),
                            _buildStepBadge('3. Arrived', isCompleted: active.status.index >= IncidentStatus.ARRIVED.index),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  // Incident Details Card
                  WariCard(
                    borderColor: WariColors.primary.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(active.category.displayName, style: WariTypography.titleMedium.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold)),
                        const Divider(height: 16),
                        _buildDetailRow(Icons.person_outline, 'Reporter Varkari', '${active.reporterName} (${active.reporterRole})'),
                        _buildDetailRow(Icons.phone_outlined, 'Contact Phone', active.reporterPhone.isNotEmpty ? active.reporterPhone : 'Available in dispatch'),
                        _buildDetailRow(Icons.warning_amber_rounded, 'Severity Level', active.severity.displayName),
                        _buildDetailRow(Icons.description_outlined, 'Details', active.description.isNotEmpty ? active.description : 'Immediate assistance requested'),
                        _buildDetailRow(Icons.near_me_outlined, 'Location', '${active.latitude.toStringAsFixed(4)}, ${active.longitude.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  // Action Workflow Controls
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchNavigation(active.latitude, active.longitude),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('START MAP NAVIGATION', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(height: WariSpacing.xs),

                  if (active.status == IncidentStatus.ACCEPTED)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => provider.setEnRoute(active.incidentId),
                        icon: const Icon(Icons.directions_run_rounded, color: WariColors.primary),
                        label: const Text('MARK EN ROUTE TO VARKARI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (active.status == IncidentStatus.EN_ROUTE)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => provider.markArrived(active.incidentId),
                        icon: const Icon(Icons.location_on_rounded, color: WariColors.success),
                        label: const Text('MARK ARRIVED AT VARKARI', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (active.status == IncidentStatus.ARRIVED)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showResolveDialog(context, provider, active.incidentId),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('RESOLVE & COMPLETE TASK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: WariColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStepBadge(String label, {bool isCompleted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? WariColors.primary : WariColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isCompleted ? Colors.white : WariColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: WariColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: WariTypography.caption.copyWith(color: WariColors.textPrimary), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
