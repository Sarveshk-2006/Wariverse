import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';

/// Crowdsourced route issue report dialog / bottom sheet.
class ReportIssueBottomSheet extends StatefulWidget {
  const ReportIssueBottomSheet({super.key});

  @override
  State<ReportIssueBottomSheet> createState() => _ReportIssueBottomSheetState();
}

class _ReportIssueBottomSheetState extends State<ReportIssueBottomSheet> {
  String? _reportedLabel;

  static const List<({String emoji, String label})> _hazards = [
    (emoji: '🌊', label: 'Muddy / Flooded'),
    (emoji: '🚧', label: 'Path Blocked'),
    (emoji: '👥', label: 'Heavy Crowd / Stampede Risk'),
    (emoji: '🐍', label: 'Animal Hazard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⚠️ Report Route Issue', style: WariTypography.headlineSmall.copyWith(color: WariColors.danger)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Text(
            'Help re-route other pilgrims by reporting live ground conditions.',
            style: WariTypography.bodySmall,
          ),
          const SizedBox(height: WariSpacing.base),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: WariSpacing.sm,
            crossAxisSpacing: WariSpacing.sm,
            childAspectRatio: 2.2,
            children: _hazards.map((h) {
              final isDone = _reportedLabel == h.label;
              return InkWell(
                onTap: () {
                  setState(() {
                    _reportedLabel = h.label;
                  });
                  Future.delayed(const Duration(milliseconds: 1200), () {
                    if (mounted && context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDone ? WariColors.successLight : WariColors.slate50,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                    border: Border.all(
                      color: isDone ? WariColors.success : WariColors.border,
                      width: isDone ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(WariSpacing.xs),
                  child: Row(
                    children: [
                      Text(isDone ? '✅' : h.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: WariSpacing.xs),
                      Expanded(
                        child: Text(
                          isDone ? 'Reported' : h.label,
                          style: WariTypography.labelSmall.copyWith(
                            fontSize: 11,
                            color: isDone ? WariColors.success : WariColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: WariSpacing.base),
          WariSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
