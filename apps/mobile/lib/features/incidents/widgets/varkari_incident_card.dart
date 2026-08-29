import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/incident_provider.dart';
import '../../../models/threat_incident_model.dart';
import '../../../core/theme/wari_theme_exports.dart';

/// Embedded card on Varkari Dashboard displaying "My Active Report" with four explicit UI states:
/// LOADING, ERROR, NO ACTIVE REPORT, and ACTIVE REPORT.
class VarkariIncidentCard extends StatelessWidget {
  const VarkariIncidentCard({super.key, required this.onReportPressed});

  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IncidentProvider>(context);

    // 1. Loading State
    if (provider.isLoading) {
      return _buildLoadingCard();
    }

    // 2. Error State
    if (provider.hasError) {
      return _buildErrorCard(context, provider);
    }

    final incident = provider.myActiveIncident;

    // 3. No Active Report State
    if (incident == null || !incident.isActive) {
      return _buildReportPromptCard(context);
    }

    // 4. Active Report State
    final networkStatus = provider.networkStatus;

    Color severityColor;
    switch (incident.severity) {
      case IncidentSeverity.LOW: severityColor = WariColors.success; break;
      case IncidentSeverity.MEDIUM: severityColor = WariColors.warning; break;
      case IncidentSeverity.HIGH: severityColor = WariColors.crowdOrange; break;
      case IncidentSeverity.CRITICAL: severityColor = WariColors.danger; break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(color: severityColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category & Severity Badge & Network Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: severityColor, size: 20),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Active Report',
                        style: WariTypography.titleMedium.copyWith(fontSize: 15),
                      ),
                      Text(
                        '${incident.category.displayName} • ${incident.severity.name}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: severityColor),
                      ),
                    ],
                  ),
                ],
              ),
              _buildNetworkBadge(networkStatus),
            ],
          ),
          const SizedBox(height: WariSpacing.md),

          // Lifecycle Status Tracker
          _buildLifecycleTracker(incident.status),
          const SizedBox(height: WariSpacing.md),

          // Responder Info Card
          Container(
            padding: const EdgeInsets.all(WariSpacing.sm),
            decoration: BoxDecoration(
              color: WariColors.background,
              borderRadius: BorderRadius.circular(WariSpacing.md),
              border: Border.all(color: WariColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded, color: WariColors.primary, size: 24),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.assignedVolunteerName != null
                            ? 'Responder: ${incident.assignedVolunteerName}'
                            : 'Responder: Finding Nearest Available Volunteer...',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      if (incident.assignedVolunteerPhone != null && incident.assignedVolunteerPhone!.isNotEmpty)
                        Text('Contact: ${incident.assignedVolunteerPhone}', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.sm),

          // Cancel Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => provider.cancelIncident(incident.incidentId),
              icon: const Icon(Icons.cancel_outlined, size: 16, color: WariColors.textMuted),
              label: const Text('Cancel Report', style: TextStyle(fontSize: 11, color: WariColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(color: WariColors.border),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: WariColors.primary),
          ),
          SizedBox(width: WariSpacing.md),
          Expanded(
            child: Text(
              'Syncing live threat reporting status...',
              style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, IncidentProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(color: WariColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.signal_wifi_off_rounded, color: WariColors.warning, size: 24),
          const SizedBox(width: WariSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.errorMessage ?? 'Live incident updates unavailable',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                ),
                const Text(
                  'Tap retry to reconnect to Cloud Firestore streams.',
                  style: TextStyle(fontSize: 10, color: WariColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => provider.retry(),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              side: const BorderSide(color: WariColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPromptCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.danger.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(color: WariColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WariColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: WariColors.danger, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Continuous Threat Reporting',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: WariColors.danger,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Report any medical, security, stampede, crowd or infrastructure hazards for real-time dispatch.',
            style: TextStyle(fontSize: 11, color: WariColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReportPressed,
              icon: const Icon(Icons.report_problem_rounded, size: 16),
              label: const Text('Report Threat / Issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: WariColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleTracker(IncidentStatus status) {
    int stepIndex = 0;
    switch (status) {
      case IncidentStatus.CREATED:
      case IncidentStatus.ASSIGNING:
        stepIndex = 1;
        break;
      case IncidentStatus.ASSIGNED:
        stepIndex = 2;
        break;
      case IncidentStatus.ACCEPTED:
        stepIndex = 3;
        break;
      case IncidentStatus.EN_ROUTE:
        stepIndex = 4;
        break;
      case IncidentStatus.ARRIVED:
        stepIndex = 5;
        break;
      case IncidentStatus.RESOLVED:
        stepIndex = 6;
        break;
      default:
        stepIndex = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Response Status: ${status.displayName}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.primary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStepCircle(1, stepIndex, 'Created'),
            _buildStepLine(1, stepIndex),
            _buildStepCircle(2, stepIndex, 'Assigned'),
            _buildStepLine(2, stepIndex),
            _buildStepCircle(3, stepIndex, 'Accepted'),
            _buildStepLine(3, stepIndex),
            _buildStepCircle(4, stepIndex, 'En Route'),
            _buildStepLine(4, stepIndex),
            _buildStepCircle(5, stepIndex, 'Arrived'),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, int currentStepIndex, String label) {
    final isDone = currentStepIndex >= stepNumber;
    final isCurrent = currentStepIndex == stepNumber;
    final color = isDone ? WariColors.success : (isCurrent ? WariColors.primary : WariColors.textMuted);

    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isDone ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isDone ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepLine(int stepNumber, int currentStepIndex) {
    final isDone = currentStepIndex > stepNumber;
    final color = isDone ? WariColors.success : WariColors.border;
    return Expanded(
      child: Container(
        height: 2,
        color: color,
        margin: const EdgeInsets.only(bottom: 12),
      ),
    );
  }

  Widget _buildNetworkBadge(IncidentNetworkStatus status) {
    Color bg;
    String label;
    switch (status) {
      case IncidentNetworkStatus.LIVE:
        bg = WariColors.success;
        label = 'LIVE';
        break;
      case IncidentNetworkStatus.SYNCING:
        bg = WariColors.warning;
        label = 'SYNCING';
        break;
      case IncidentNetworkStatus.OFFLINE:
        bg = WariColors.danger;
        label = 'OFFLINE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bg)),
        ],
      ),
    );
  }
}
