import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/qr_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final role = userProvider.currentRole;

    return Container(
      padding: const EdgeInsets.all(WariSpacing.base),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
        border: Border.all(color: WariColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: WariColors.primary.withValues(alpha: 0.15),
                    radius: 22,
                    child: Text(
                      user?.displayName.substring(0, 1).toUpperCase() ?? 'V',
                      style: WariTypography.headlineSmall.copyWith(color: WariColors.primary),
                    ),
                  ),
                  const SizedBox(width: WariSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Respected Pilgrim',
                        style: WariTypography.titleMedium,
                      ),
                      Text(
                        'Role: ${role.name} • ${user?.email ?? "Realtime Device Active"}',
                        style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              WariStatusChip(
                label: role.name,
                color: WariColors.primary,
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.md),
          Container(
            padding: const EdgeInsets.all(WariSpacing.sm),
            decoration: BoxDecoration(
              color: WariColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
              border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: WariColors.primary, size: 20),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    'Palkhi Route: Alandi → Pandharpur • Live GPS Connected',
                    style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.md),
          const Divider(),
          const SizedBox(height: WariSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 18, color: WariColors.primary),
                  const SizedBox(width: WariSpacing.xs),
                  Text('Digital Pilgrim ID', style: WariTypography.labelSmall),
                ],
              ),
              WariSecondaryButtonInline(
                label: 'Show e-ID QR',
                onPressed: () => _showQrModal(context, user?.userId ?? 'varkari-001'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, String userId) {
    final qrProvider = Provider.of<QrProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(WariSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<WariQrCode>(
                future: qrProvider.getOrCreatePilgrimIdQr(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(WariSpacing.xl),
                      child: WariLoadingIndicator(message: 'Generating Secure Token QR...'),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(WariSpacing.md),
                      child: Text('Error generating QR: ${snapshot.error}'),
                    );
                  }

                  final qr = snapshot.data!;
                  return WariQrCard(
                    qrCode: qr,
                    title: 'Digital Pilgrim Identity Card',
                    subtitle: 'Scan to verify identity safely without revealing private phone or address.',
                    onRegenerate: () async {
                      await qrProvider.regenerateQr(qr.id, userId);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
                    onRevoke: () async {
                      await qrProvider.revokeQr(qr.id, userId);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
                    onPrintShare: () {},
                  );
                },
              ),
              const SizedBox(height: WariSpacing.sm),
              WariPrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
