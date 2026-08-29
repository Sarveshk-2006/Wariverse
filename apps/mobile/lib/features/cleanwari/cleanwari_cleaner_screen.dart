import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// CleanWari Operational Dashboard for Sanitation Cleaner Staff (UserRole.CLEANER).
class CleanWariCleanerScreen extends StatefulWidget {
  const CleanWariCleanerScreen({super.key});

  @override
  State<CleanWariCleanerScreen> createState() => _CleanWariCleanerScreenState();
}

class _CleanWariCleanerScreenState extends State<CleanWariCleanerScreen> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService)),
      child: const _CleanWariCleanerContent(),
    );
  }
}

class _CleanWariCleanerContent extends StatefulWidget {
  const _CleanWariCleanerContent();

  @override
  State<_CleanWariCleanerContent> createState() => _CleanWariCleanerContentState();
}

class _CleanWariCleanerContentState extends State<_CleanWariCleanerContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CleanWariProvider>(context, listen: false).loadReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CleanWariProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('CleanWari Staff Operations (स्वच्छता अधिकारी)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(message: 'Staff Operational Feed — Real-time toilet dispatch tasks'),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CleanWariProvider provider) {
    final reports = provider.reports;

    if (reports.isEmpty) {
      return const WariEmptyState(
        icon: Icons.cleaning_services,
        title: 'No Active Cleanliness Tasks',
        subtitle: 'All assigned facilities are clean and operational.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final isHigh = report.isHighPriority;

        return Padding(
          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariCard(
            borderColor: isHigh ? WariColors.warning : WariColors.border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(report.priority.name, style: WariTypography.labelSmall.copyWith(
                      color: isHigh ? WariColors.warning : WariColors.primary,
                      fontWeight: FontWeight.bold,
                    )),
                    WariStatusChip(
                      label: report.status.name,
                      color: report.isResolved ? WariColors.success : WariColors.warning,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(report.toiletName, style: WariTypography.titleMedium),
                Text('Issue: ${report.issueType.displayName}', style: WariTypography.bodyMedium),
                const SizedBox(height: WariSpacing.sm),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    WariSecondaryButtonInline(
                      label: 'Open Task Execution →',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.cleanWariTask,
                        arguments: report,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
