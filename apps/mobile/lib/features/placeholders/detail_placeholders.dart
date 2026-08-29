import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';

class GenericDetailPlaceholder extends StatelessWidget {
  const GenericDetailPlaceholder({
    super.key,
    required this.title,
    required this.category,
    this.id,
  });

  final String title;
  final String category;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: WariCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WariStatusChip(label: category, color: WariColors.primary),
              const SizedBox(height: WariSpacing.sm),
              Text(title, style: WariTypography.headlineMedium),
              if (id != null) ...[
                const SizedBox(height: 4),
                Text('ID: $id', style: WariTypography.caption),
              ],
              const SizedBox(height: WariSpacing.base),
              const DetailRow(label: 'Status', value: 'Active'),
              const DetailRow(label: 'Last Updated', value: 'Just now'),
              const DetailRow(label: 'Location', value: 'Pandharpur Wari Route'),
              const SizedBox(height: WariSpacing.base),
              WariPrimaryButton(
                label: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
