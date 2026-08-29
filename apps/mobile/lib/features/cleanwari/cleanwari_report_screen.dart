import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/cleanwari_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// CleanWari issue reporting screen after scanning a toilet QR code.
class CleanWariReportScreen extends StatefulWidget {
  final String toiletId;
  final String toiletQrCode;
  final String toiletName;

  const CleanWariReportScreen({
    super.key,
    required this.toiletId,
    required this.toiletQrCode,
    required this.toiletName,
  });

  @override
  State<CleanWariReportScreen> createState() => _CleanWariReportScreenState();
}

class _CleanWariReportScreenState extends State<CleanWariReportScreen> {
  CleanlinessIssueType _selectedIssue = CleanlinessIssueType.NEEDS_CLEANING;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService))..loadReports(),
      child: Consumer<CleanWariProvider>(
        builder: (context, provider, child) {
          final user = Provider.of<UserProvider>(context, listen: false).currentUser;

          return Scaffold(
            backgroundColor: WariColors.background,
            appBar: AppBar(
              title: const Text('Report Issue (समस्या नोंदवा)'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.isDuplicateNotice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: WariSpacing.base),
                      child: WariCard(
                        borderColor: WariColors.warning,
                        child: Text(
                          '⚠️ This issue was recently reported for this toilet. Our sanitation staff has been dispatched.',
                          style: WariTypography.bodyMedium.copyWith(color: WariColors.warningDark),
                        ),
                      ),
                    ),

                  // Facility Info Header
                  WariCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(WariSpacing.xs),
                          decoration: BoxDecoration(
                            color: WariColors.primaryLight,
                            borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.wc, color: WariColors.primaryDark, size: 28),
                        ),
                        const SizedBox(width: WariSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.toiletName, style: WariTypography.titleMedium),
                              Text('QR Code: ${widget.toiletQrCode}', style: WariTypography.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  const SectionHeader(
                    title: 'What is the problem? (काय अडचण आहे?)',
                    subtitle: 'Select the cleanliness category for immediate staff dispatch',
                  ),
                  const SizedBox(height: WariSpacing.sm),

                  ...CleanlinessIssueType.values.map((issue) {
                    final isSelected = _selectedIssue == issue;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                      child: WariCard(
                        borderColor: isSelected ? WariColors.primary : WariColors.border,
                        borderWidth: isSelected ? 1.5 : 1.0,
                        onTap: () => setState(() => _selectedIssue = issue),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? WariColors.primary : WariColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(width: WariSpacing.xs),
                            Text(issue.displayName, style: WariTypography.bodyLarge),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: WariSpacing.base),

                  Text('Additional details (optional)', style: WariTypography.labelSmall),
                  const SizedBox(height: WariSpacing.xs),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Provide landmark or specific stall details...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: WariSpacing.xl),

                  WariPrimaryButton(
                    label: 'SUBMIT CLEANLINESS REPORT',
                    onPressed: () async {
                      final report = await provider.submitReport(
                        toiletId: widget.toiletId,
                        toiletQrCode: widget.toiletQrCode,
                        toiletName: widget.toiletName,
                        reporterId: user?.userId ?? 'varkari-001',
                        issueType: _selectedIssue,
                        description: _descriptionController.text,
                      );

                      if (report != null && context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.cleanWariReportStatus,
                          arguments: report,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
