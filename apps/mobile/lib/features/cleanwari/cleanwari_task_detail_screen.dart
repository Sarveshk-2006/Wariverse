import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/cleanwari_provider.dart';
import '../../repositories/cleanwari_repository.dart';
import '../../services/api_service.dart';

/// Task execution and resolution sheet for sanitation staff.
class CleanWariTaskDetailScreen extends StatefulWidget {
  final CleanlinessReport report;

  const CleanWariTaskDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<CleanWariTaskDetailScreen> createState() => _CleanWariTaskDetailScreenState();
}

class _CleanWariTaskDetailScreenState extends State<CleanWariTaskDetailScreen> {
  final _resolutionController = TextEditingController(text: 'Sanitized facility and refilled water supply.');

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CleanWariProvider>(
      create: (_) => CleanWariProvider(repository: CleanWariRepository(apiService)),
      child: Consumer<CleanWariProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: WariColors.background,
            appBar: AppBar(
              title: const Text('Execute Task (काम पूर्ण करा)'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WariCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASSIGNED TOILET', style: WariTypography.labelSmall),
                        Text(widget.report.toiletName, style: WariTypography.headlineSmall),
                        const SizedBox(height: WariSpacing.xs),
                        Text('Issue: ${widget.report.issueType.displayName}', style: WariTypography.bodyMedium),
                        Text('Reported note: "${widget.report.description}"', style: WariTypography.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  Text('Resolution Note (निवारण नोंद)', style: WariTypography.labelSmall),
                  const SizedBox(height: WariSpacing.xs),
                  TextField(
                    controller: _resolutionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Enter resolution details...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: WariSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: WariSecondaryButton(
                          label: 'IN PROGRESS',
                          onPressed: () async {
                            await provider.startCleaning(widget.report.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      Expanded(
                        child: WariPrimaryButton(
                          label: 'CONFIRM CLEANED',
                          onPressed: () async {
                            await provider.resolveTask(widget.report.id, _resolutionController.text);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
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
