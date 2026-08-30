import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/cleanliness_report.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// Sanitation History Screen for Sanitation Staff (UserRole.CLEANER).
/// Displays completed sanitation cleaning tasks.
class SanitationHistoryScreen extends StatefulWidget {
  const SanitationHistoryScreen({super.key});

  @override
  State<SanitationHistoryScreen> createState() => _SanitationHistoryScreenState();
}

class _SanitationHistoryScreenState extends State<SanitationHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService))..loadReports(),
      child: const _SanitationHistoryContent(),
    );
  }
}

class _SanitationHistoryContent extends StatelessWidget {
  const _SanitationHistoryContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CleanWariProvider>(context);
    final completed = provider.reports.where((r) => r.status == CleanlinessReportStatus.RESOLVED).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanitation Cleaning History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadReports(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const WariLoadingIndicator(message: 'Loading sanitation history...')
          : completed.isEmpty
              ? const WariEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'No Completed Tasks Yet',
                  subtitle: 'Completed sanitation tasks will appear in this history log.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(WariSpacing.base),
                  itemCount: completed.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: WariSpacing.xs),
                  itemBuilder: (ctx, i) {
                    final item = completed[i];
                    return WariCard(
                      borderColor: WariColors.success.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.issueType.displayName,
                                  style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const WariStatusChip(
                                label: 'RESOLVED',
                                color: WariColors.success,
                                dense: true,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('Facility: ${item.toiletName}', style: WariTypography.caption),
                          Text('Description: ${item.description}', style: WariTypography.caption),
                          Text('Reporter ID: ${item.reporterId}', style: WariTypography.caption),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
