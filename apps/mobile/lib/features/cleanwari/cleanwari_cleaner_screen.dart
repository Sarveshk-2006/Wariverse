import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// CleanWari Operational Field Dashboard for Sanitation Cleaner Staff (UserRole.CLEANER).
/// Powered by Cloud Firestore `sanitation_reports` real-time dispatch queue.
class CleanWariCleanerScreen extends StatefulWidget {
  const CleanWariCleanerScreen({super.key});

  @override
  State<CleanWariCleanerScreen> createState() => _CleanWariCleanerScreenState();
}

class _CleanWariCleanerScreenState extends State<CleanWariCleanerScreen> {
  @override
  Widget build(BuildContext context) {
    CleanWariProvider? provider;
    try {
      provider = Provider.of<CleanWariProvider>(context);
    } catch (_) {}

    if (provider == null) {
      final apiService = Provider.of<ApiService>(context, listen: false);
      return ChangeNotifierProvider<CleanWariProvider>(
        create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService)),
        child: const _CleanWariCleanerContent(),
      );
    }

    return const _CleanWariCleanerContent();
  }
}

class _CleanWariCleanerContent extends StatefulWidget {
  const _CleanWariCleanerContent();

  @override
  State<_CleanWariCleanerContent> createState() => _CleanWariCleanerContentState();
}

class _CleanWariCleanerContentState extends State<_CleanWariCleanerContent> {
  String _selectedFilter = 'ALL'; // ALL, CRITICAL, IN_PROGRESS, RESOLVED

  Color _getPriorityColor(CleanlinessReportPriority priority) {
    switch (priority) {
      case CleanlinessReportPriority.HIGH:
        return WariColors.danger;
      case CleanlinessReportPriority.MEDIUM:
        return const Color(0xFFF97316); // Orange
      case CleanlinessReportPriority.LOW:
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getStatusColor(CleanlinessReportStatus status) {
    switch (status) {
      case CleanlinessReportStatus.RESOLVED:
        return WariColors.success;
      case CleanlinessReportStatus.IN_PROGRESS:
        return const Color(0xFF8B5CF6); // Purple
      case CleanlinessReportStatus.ACCEPTED:
        return const Color(0xFFF59E0B); // Amber
      case CleanlinessReportStatus.ASSIGNED:
      case CleanlinessReportStatus.REPORTED:
      default:
        return WariColors.danger;
    }
  }

  void _showResolutionDialog(BuildContext context, CleanWariProvider provider, String reportId) {
    final noteController = TextEditingController(text: 'Issue resolved. Sanitation spray applied and facility cleaned.');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: WariColors.success, size: 24),
                  SizedBox(width: 8),
                  Text('Complete Sanitation Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes / Actions Taken',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WariColors.success,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final note = noteController.text.trim();
                  provider.resolveTask(reportId, note.isEmpty ? 'Cleaned & sanitized' : note);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task marked RESOLVED in real time.')),
                  );
                },
                icon: const Icon(Icons.verified_rounded, color: Colors.white),
                label: const Text('Mark Task Resolved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CleanWariProvider>(context);
    final reports = provider.reports;

    // Priority Engine: High -> Medium -> Low
    final sortedReports = List<CleanlinessReport>.from(reports)
      ..sort((a, b) {
        if (a.priority == b.priority) {
          return b.reportedAt.compareTo(a.reportedAt);
        }
        return a.priority == CleanlinessReportPriority.HIGH ? -1 : 1;
      });

    final filteredReports = sortedReports.where((r) {
      if (_selectedFilter == 'CRITICAL') return r.priority == CleanlinessReportPriority.HIGH;
      if (_selectedFilter == 'IN_PROGRESS') return r.status == CleanlinessReportStatus.IN_PROGRESS || r.status == CleanlinessReportStatus.ACCEPTED;
      if (_selectedFilter == 'RESOLVED') return r.status == CleanlinessReportStatus.RESOLVED;
      return true;
    }).toList();

    final newCount = reports.where((r) => r.status == CleanlinessReportStatus.REPORTED || r.status == CleanlinessReportStatus.ASSIGNED).length;
    final highCount = reports.where((r) => r.priority == CleanlinessReportPriority.HIGH && r.status != CleanlinessReportStatus.RESOLVED).length;
    final activeCount = reports.where((r) => r.status == CleanlinessReportStatus.IN_PROGRESS || r.status == CleanlinessReportStatus.ACCEPTED).length;
    final resolvedCount = reports.where((r) => r.status == CleanlinessReportStatus.RESOLVED).length;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('CleanWari Staff Operations (स्वच्छता अधिकारी)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadReports(),
            tooltip: 'Refresh Task Queue',
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics Header Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildMetricCard('New', newCount.toString(), WariColors.danger),
                const SizedBox(width: 8),
                _buildMetricCard('High Priority', highCount.toString(), const Color(0xFFF97316)),
                const SizedBox(width: 8),
                _buildMetricCard('In Progress', activeCount.toString(), const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _buildMetricCard('Resolved', resolvedCount.toString(), WariColors.success),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Tasks (${reports.length})'),
                  const SizedBox(width: 6),
                  _buildFilterChip('CRITICAL', 'High Priority ($highCount)'),
                  const SizedBox(width: 6),
                  _buildFilterChip('IN_PROGRESS', 'Active ($activeCount)'),
                  const SizedBox(width: 6),
                  _buildFilterChip('RESOLVED', 'Resolved ($resolvedCount)'),
                ],
              ),
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const WariLoadingIndicator(message: 'Loading Sanitation Task Feed...')
                : filteredReports.isEmpty
                    ? const WariEmptyState(
                        icon: Icons.cleaning_services_outlined,
                        title: 'No Sanitation Tasks',
                        subtitle: 'No dispatch tasks match your current filter.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(WariSpacing.base),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          final prioColor = _getPriorityColor(report.priority);
                          final statusColor = _getStatusColor(report.status);
                          final timeStr = DateFormat('MMM dd, hh:mm a').format(report.reportedAt);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 5, color: prioColor, height: 160),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  report.issueType.displayName,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  report.status.displayName.toUpperCase(),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Facility: ${report.toiletName}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WariColors.primaryDark),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            report.description,
                                            style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 13, color: WariColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(timeStr, style: const TextStyle(fontSize: 11, color: WariColors.textMuted)),
                                              const Spacer(),
                                              if (report.assignedCleanerName != null)
                                                Text(
                                                  'Assigned: ${report.assignedCleanerName}',
                                                  style: const TextStyle(fontSize: 11, color: WariColors.primary, fontWeight: FontWeight.w600),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              if (report.status != CleanlinessReportStatus.RESOLVED) ...[
                                                if (report.status == CleanlinessReportStatus.REPORTED || report.status == CleanlinessReportStatus.ASSIGNED)
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: WariColors.primary,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                      onPressed: () => provider.acceptTask(report.id),
                                                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                                      label: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                if (report.status == CleanlinessReportStatus.ACCEPTED)
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF8B5CF6),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                      onPressed: () => provider.startCleaning(report.id),
                                                      icon: const Icon(Icons.directions_run_rounded, size: 16, color: Colors.white),
                                                      label: const Text('Start Work', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                if (report.status == CleanlinessReportStatus.IN_PROGRESS)
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: WariColors.success,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                      onPressed: () => _showResolutionDialog(context, provider, report.id),
                                                      icon: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                                                      label: const Text('Resolve', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                              ],
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: WariColors.info,
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                ),
                                                onPressed: () async {
                                                  final uri = Uri.parse('https://maps.google.com/?q=18.5204,73.8567');
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  }
                                                },
                                                icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
                                                label: const Text('Maps', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : WariColors.textPrimary,
        ),
      ),
      selectedColor: WariColors.primary,
      backgroundColor: WariColors.background,
      checkmarkColor: Colors.white,
      onSelected: (_) {
        setState(() {
          _selectedFilter = key;
        });
      },
    );
  }
}
