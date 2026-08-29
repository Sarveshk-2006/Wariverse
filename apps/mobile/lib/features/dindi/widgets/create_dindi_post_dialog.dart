import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

/// Modal dialog for publishing updates to the private Dindi community feed.
class CreateDindiPostDialog extends StatefulWidget {
  const CreateDindiPostDialog({
    super.key,
    required this.userRole,
    required this.onSubmit,
  });

  final UserRole userRole;
  final Function(String content, DindiPostType type) onSubmit;

  @override
  State<CreateDindiPostDialog> createState() => _CreateDindiPostDialogState();
}

class _CreateDindiPostDialogState extends State<CreateDindiPostDialog> {
  final TextEditingController _contentController = TextEditingController();
  DindiPostType _selectedType = DindiPostType.GENERAL;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WariSpacing.xs),
                  decoration: BoxDecoration(
                    color: WariColors.primaryLight,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.campaign, color: WariColors.primaryDark, size: 24),
                ),
                const SizedBox(width: WariSpacing.xs),
                Text('Post Dindi Update (अपडेट पोस्ट करा)', style: WariTypography.titleMedium),
              ],
            ),
            const Divider(height: WariSpacing.base),

            // Post Category Selector
            Text('Update Type:', style: WariTypography.labelSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<DindiPostType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(WariSpacing.radiusSm)),
              ),
              items: DindiPostType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName, style: WariTypography.bodySmall),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: WariSpacing.sm),

            // Content Field
            Text('Update Message:', style: WariTypography.labelSmall),
            const SizedBox(height: 4),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share route updates, halt notices, or general pilgrim information...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(WariSpacing.radiusSm)),
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel (रद्द करा)'),
                ),
                const SizedBox(width: WariSpacing.xs),
                WariPrimaryButton(
                  label: 'Post Update',
                  fullWidth: false,
                  dense: true,
                  onPressed: () {
                    final text = _contentController.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context);
                      widget.onSubmit(text, _selectedType);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
