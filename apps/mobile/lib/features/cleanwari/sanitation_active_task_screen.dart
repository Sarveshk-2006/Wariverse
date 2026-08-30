import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/cleanliness_report.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// Sanitation Active Task Screen for Sanitation Staff (UserRole.CLEANER).
/// Displays ONLY the sanitation task currently accepted & handled by this worker.
class SanitationActiveTaskScreen extends StatefulWidget {
  const SanitationActiveTaskScreen({super.key});

  @override
  State<SanitationActiveTaskScreen> createState() => _SanitationActiveTaskScreenState();
}

class _SanitationActiveTaskScreenState extends State<SanitationActiveTaskScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService))..loadReports(),
      child: const _SanitationActiveTaskContent(),
    );
  }
}

class _SanitationActiveTaskContent extends StatelessWidget {
  const _SanitationActiveTaskContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CleanWariProvider>(context);
    final reports = provider.reports;
    final active = reports.firstWhere(
      (r) => r.status == CleanlinessReportStatus.ACCEPTED || r.status == CleanlinessReportStatus.IN_PROGRESS,
      orElse: () => reports.isNotEmpty ? reports.first : reports.first,
    );

    final hasActive = reports.isNotEmpty && (active.status == CleanlinessReportStatus.ACCEPTED || active.status == CleanlinessReportStatus.IN_PROGRESS);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanitation Active Task'),
      ),
      body: !hasActive
          ? const Center(
              child: WariEmptyState(
                icon: Icons.cleaning_services_outlined,
                title: 'No Active Sanitation Task',
                subtitle: 'Accept a cleaning dispatch request from the Tasks queue.',
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            const Text('Sanitation Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            WariStatusChip(label: active.status.displayName, color: WariColors.primary, dense: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStepBadge('1. Accepted', isCompleted: active.status == CleanlinessReportStatus.ACCEPTED || active.status == CleanlinessReportStatus.IN_PROGRESS || active.status == CleanlinessReportStatus.RESOLVED),
                            const Icon(Icons.arrow_forward, size: 14, color: WariColors.textMuted),
                            _buildStepBadge('2. In Progress', isCompleted: active.status == CleanlinessReportStatus.IN_PROGRESS || active.status == CleanlinessReportStatus.RESOLVED),
                            const Icon(Icons.arrow_forward, size: 14, color: WariColors.textMuted),
                            _buildStepBadge('3. Cleaned', isCompleted: active.status == CleanlinessReportStatus.RESOLVED),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  WariCard(
                    borderColor: WariColors.primary.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(active.issueType.displayName, style: WariTypography.titleMedium.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold)),
                        const Divider(height: 16),
                        _buildDetailRow(Icons.place_outlined, 'Facility Name', active.toiletName),
                        _buildDetailRow(Icons.description_outlined, 'Description', active.description),
                        _buildDetailRow(Icons.person_outline, 'Reporter ID', active.reporterId),
                        _buildDetailRow(Icons.warning_amber_rounded, 'Priority', active.isHighPriority ? 'HIGH PRIORITY' : 'NORMAL'),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  if (active.status == CleanlinessReportStatus.ACCEPTED)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await provider.startCleaning(active.id);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('🧹 Cleaning started! Status updated to IN PROGRESS.')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('START CLEANING WORK', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),

                  if (active.status == CleanlinessReportStatus.IN_PROGRESS)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await provider.resolveTask(active.id, 'Completed sanitation & hygiene cleaning.');
                          messenger.showSnackBar(
                            const SnackBar(content: Text('✅ Sanitation Task COMPLETED! Moved to History.'), backgroundColor: WariColors.success),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('MARK CLEANING COMPLETED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        style: TextStyle(color: isCompleted ? Colors.white : WariColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
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
