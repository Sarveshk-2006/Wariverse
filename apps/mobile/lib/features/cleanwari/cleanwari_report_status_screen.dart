import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';

/// Varkari-facing status tracking screen for a submitted CleanWari report.
class CleanWariReportStatusScreen extends StatelessWidget {
  final CleanlinessReport report;

  const CleanWariReportStatusScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Cleanliness Report Status (अहवाल स्थिती)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.isDemo)
              const OfflineBanner(message: 'Demo Mode — Sanitation task dispatched to mock cleaner staff'),

            // Confirmation Header Card
            WariCard(
              borderColor: WariColors.success,
              borderWidth: 1.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: WariColors.success, size: 28),
                      const SizedBox(width: WariSpacing.xs),
                      Text('REPORT RECEIVED', style: WariTypography.titleMedium.copyWith(color: WariColors.success)),
                    ],
                  ),
                  const SizedBox(height: WariSpacing.xs),
                  Text(
                    'Your cleanliness issue report has been received and assigned to sanitation staff.',
                    style: WariTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // Report Details Card
            WariCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FACILITY & ISSUE', style: WariTypography.labelSmall),
                  const SizedBox(height: WariSpacing.xs),
                  Text(report.toiletName, style: WariTypography.headlineSmall),
                  const SizedBox(height: WariSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Issue: ${report.issueType.displayName}', style: WariTypography.bodyMedium),
                      WariStatusChip(
                        label: report.priority.name,
                        color: report.isHighPriority ? WariColors.warning : WariColors.primary,
                        dense: true,
                      ),
                    ],
                  ),
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: WariSpacing.xs),
                    Text('Note: "${report.description}"', style: WariTypography.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            const SectionHeader(
              title: 'Dispatch Timeline (नियुक्ती प्रगती)',
              subtitle: 'Real-time cleaner assignment and issue resolution state',
            ),
            const SizedBox(height: WariSpacing.sm),

            _buildTimelineItem(
              title: '✓ REPORTED',
              subtitle: 'Submitted by Varkari pilgrim',
              isCompleted: true,
            ),
            _buildTimelineItem(
              title: '✓ ASSIGNED',
              subtitle: report.assignedCleanerName != null
                  ? 'Assigned to cleaner: ${report.assignedCleanerName}'
                  : 'Assigning nearest sanitation team member...',
              isCompleted: report.status.index >= CleanlinessReportStatus.ASSIGNED.index,
            ),
            _buildTimelineItem(
              title: '● IN PROGRESS',
              subtitle: 'Sanitation staff active on site',
              isCompleted: report.status.index >= CleanlinessReportStatus.IN_PROGRESS.index,
            ),
            _buildTimelineItem(
              title: '✓ RESOLVED',
              subtitle: report.resolutionNote ?? 'Facility sanitized and inspected',
              isCompleted: report.status == CleanlinessReportStatus.RESOLVED,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? WariColors.success : WariColors.textMuted,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? WariColors.success : WariColors.border,
              ),
          ],
        ),
        const SizedBox(width: WariSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WariTypography.titleSmall.copyWith(
                  color: isCompleted ? WariColors.primaryDark : WariColors.textMuted,
                ),
              ),
              Text(subtitle, style: WariTypography.caption),
              const SizedBox(height: WariSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}
