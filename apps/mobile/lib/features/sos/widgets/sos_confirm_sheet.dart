import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/sos_provider.dart';
import '../../../providers/user_provider.dart';

/// SOS Trigger confirmation bottom sheet modal.
class SosConfirmSheet extends StatefulWidget {
  const SosConfirmSheet({super.key});

  @override
  State<SosConfirmSheet> createState() => _SosConfirmSheetState();
}

class _SosConfirmSheetState extends State<SosConfirmSheet> {
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return Container(
      padding: const EdgeInsets.all(WariSpacing.base),
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: WariColors.danger, size: 24),
                    const SizedBox(width: WariSpacing.xs),
                    Text('Confirm Emergency SOS', style: WariTypography.titleMedium.copyWith(color: WariColors.danger)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: '',
                  onPressed: () => sosProvider.cancelConfirming(),
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.sm),

            Text(
              'Select emergency category to alert nearby medical teams and volunteers immediately:',
              style: WariTypography.bodyMedium,
            ),
            const SizedBox(height: WariSpacing.sm),

            Wrap(
              spacing: WariSpacing.xs,
              runSpacing: WariSpacing.xs,
              children: SOSCategory.values.map((cat) {
                final isSelected = sosProvider.selectedCategory == cat;
                return GestureDetector(
                  onTap: () => sosProvider.setSelectedCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? WariColors.danger : WariColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? WariColors.danger : WariColors.border),
                    ),
                    child: Text(
                      cat.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : WariColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: WariSpacing.sm),

            TextField(
              controller: _descController,
              onChanged: (val) => sosProvider.setDescription(val),
              decoration: const InputDecoration(
                hintText: 'Add description / landmark details (optional)...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            Row(
              children: [
                Expanded(
                  child: WariSecondaryButton(
                    label: 'CANCEL',
                    onPressed: () => sosProvider.cancelConfirming(),
                  ),
                ),
                const SizedBox(width: WariSpacing.sm),
                Expanded(
                  flex: 2,
                  child: WariPrimaryButton(
                    label: 'SEND SOS NOW',
                    icon: Icons.emergency,
                    backgroundColor: WariColors.danger,
                    onPressed: () {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final userId = userProvider.currentUser?.userId;
                      sosProvider.triggerSos(
                        category: sosProvider.selectedCategory,
                        description: sosProvider.description,
                        userId: userId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
