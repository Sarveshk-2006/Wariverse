import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/dindi_repository.dart';
import '../../services/api_service.dart';

/// Digital Dindi Pass Screen displaying the pilgrim's official devotional credential card.
class DigitalDindiPassScreen extends StatelessWidget {
  const DigitalDindiPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    return ChangeNotifierProvider<DindiProvider>(
      create: (_) {
        final provider = DindiProvider(repository: DindiRepository(apiService));
        provider.loadDindis().then((_) {
          provider.joinDindi('dindi-001', user?.userId ?? 'varkari-001', userName: user?.displayName ?? 'Pilgrim');
        });
        return provider;
      },
      child: const _DigitalDindiPassContent(),
    );
  }
}

class _DigitalDindiPassContent extends StatelessWidget {
  const _DigitalDindiPassContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    final pass = provider.currentPass;
    final dindi = provider.currentDindi;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Digital Dindi Pass (डिजिटल पास)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          children: [
            if (pass == null || dindi == null) ...[
              const WariEmptyState(
                icon: Icons.qr_code_2,
                title: 'No Active Digital Pass',
                subtitle: 'Join a Dindi to issue your official digital pilgrimage pass.',
              ),
              const SizedBox(height: WariSpacing.base),
              WariPrimaryButton(
                label: 'Join a Dindi',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.dindiJoin),
              ),
            ] else ...[
              // Digital Credential Pass Card
              WariCard(
                borderColor: WariColors.primary,
                borderWidth: 2,
                child: Column(
                  children: [
                    // Header Saffron Branding Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(WariSpacing.sm),
                      decoration: BoxDecoration(
                        color: WariColors.primary,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'WariVerse AI',
                            style: WariTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'DIGITAL DINDI PASS (डिजिटल दिंडी पास)',
                            style: WariTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WariSpacing.base),

                    // Dindi Name & Pramukh
                    Text(
                      dindi.name,
                      style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Pramukh: ${dindi.leaderName}',
                      style: WariTypography.bodySmall,
                    ),
                    const SizedBox(height: WariSpacing.base),

                    // QR Code View
                    Container(
                      padding: const EdgeInsets.all(WariSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                        border: Border.all(color: WariColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: user?.formattedQrPayload ?? pass.qrPayload,
                        version: QrVersions.auto,
                        size: 180.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: WariColors.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: WariColors.slate800,
                        ),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.base),

                    // Pilgrim Details & Pass ID
                    Text(
                      user?.displayName ?? pass.userName,
                      style: WariTypography.titleMedium,
                    ),
                    Text(
                      'Role: ${user?.userRole.displayName ?? 'Varkari Pilgrim'}',
                      style: WariTypography.caption,
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: WariColors.slate100,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                      ),
                      child: Text(
                        'PASS ID: ${pass.passId}',
                        style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.sm),

                    const WariStatusChip(
                      label: 'ACTIVE PASS',
                      color: WariColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),

              WariSecondaryButton(
                label: 'Back to My Dindi',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.dindi),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
