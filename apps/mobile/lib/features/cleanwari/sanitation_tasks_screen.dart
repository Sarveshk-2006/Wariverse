import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/cleanliness_report.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// Sanitation Tasks Screen for Sanitation Staff (UserRole.CLEANER).
/// Displays active toilet cleaning requests, waste overflow, and hygiene dispatches.
class SanitationTasksScreen extends StatefulWidget {
  const SanitationTasksScreen({super.key});

  @override
  State<SanitationTasksScreen> createState() => _SanitationTasksScreenState();
}

class _SanitationTasksScreenState extends State<SanitationTasksScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService))..loadReports(),
      child: const _SanitationTasksContent(),
    );
  }
}

class _SanitationTasksContent extends StatelessWidget {
  const _SanitationTasksContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CleanWariProvider>(context);
    final reports = provider.reports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanitation & Hygiene Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadReports(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const WariLoadingIndicator(message: 'Fetching sanitation tasks from Firestore...')
          : reports.isEmpty
              ? const WariEmptyState(
                  icon: Icons.cleaning_services_outlined,
                  title: 'No Pending Sanitation Tasks',
                  subtitle: 'All assigned route facilities are currently clean.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(WariSpacing.base),
                  itemCount: reports.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: WariSpacing.xs),
                  itemBuilder: (ctx, i) {
                    final item = reports[i];
                    return WariCard(
                      borderColor: item.isHighPriority ? WariColors.warning : WariColors.border,
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
                              WariStatusChip(
                                label: item.status.displayName,
                                color: item.isHighPriority ? WariColors.danger : WariColors.warning,
                                dense: true,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('Facility: ${item.toiletName}', style: WariTypography.caption),
                          Text('Description: ${item.description}', style: WariTypography.caption),
                          Text('Reporter ID: ${item.reporterId}', style: WariTypography.caption),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await provider.acceptTask(item.id);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('✅ Sanitation Task "${item.issueType.displayName}" Accepted! Moved to Active Task.')),
                                );
                              },
                              icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                              label: const Text('ACCEPT SANITATION TASK'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
