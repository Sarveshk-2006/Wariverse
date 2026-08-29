import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';

/// Modal dialog presented after scanning a Dindi QR payload to confirm registration.
class DindiJoinConfirmationDialog extends StatelessWidget {
  const DindiJoinConfirmationDialog({
    super.key,
    required this.dindi,
    required this.isAlreadyMember,
    required this.onConfirmJoin,
  });

  final Dindi dindi;
  final bool isAlreadyMember;
  final VoidCallback onConfirmJoin;

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
                  child: const Icon(Icons.qr_code_scanner, color: WariColors.primaryDark, size: 24),
                ),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Dindi Join (दिंडी नोंदणी)',
                        style: WariTypography.titleMedium,
                      ),
                      Text(
                        'Verified Procession Unit',
                        style: WariTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: WariSpacing.base),

            Text(
              dindi.name,
              style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.person, size: 14, color: WariColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Leader: ${dindi.leaderName}',
                  style: WariTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.groups, size: 14, color: WariColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Members: ${dindi.memberCount} Varkaris',
                  style: WariTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.route, size: 14, color: WariColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Route: ${dindi.routeSection}',
                    style: WariTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.base),

            if (isAlreadyMember) ...[
              Container(
                padding: const EdgeInsets.all(WariSpacing.xs),
                decoration: BoxDecoration(
                  color: WariColors.infoLight,
                  borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  border: Border.all(color: WariColors.info),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: WariColors.info),
                    const SizedBox(width: WariSpacing.xs),
                    Expanded(
                      child: Text(
                        'You are already an active member of this Dindi.',
                        style: WariTypography.labelSmall.copyWith(color: WariColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel (रद्द करा)'),
                ),
                const SizedBox(width: WariSpacing.xs),
                if (!isAlreadyMember)
                  WariPrimaryButton(
                    label: 'Join This Dindi',
                    fullWidth: false,
                    dense: true,
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirmJoin();
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
