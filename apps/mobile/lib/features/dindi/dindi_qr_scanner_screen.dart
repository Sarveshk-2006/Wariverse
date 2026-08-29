import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/dindi_repository.dart';
import '../../services/api_service.dart';
import '../../services/dindi_qr_parser.dart';
import '../../services/mock_dindi_data.dart';
import 'dindi_join_confirmation_dialog.dart';

/// Interactive QR Scanner screen for joining a Dindi procession batch.
class DindiQrScannerScreen extends StatefulWidget {
  const DindiQrScannerScreen({super.key});

  @override
  State<DindiQrScannerScreen> createState() => _DindiQrScannerScreenState();
}

class _DindiQrScannerScreenState extends State<DindiQrScannerScreen> {
  final TextEditingController _manualQrController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _manualQrController.dispose();
    super.dispose();
  }

  void _handlePayloadScanned(String rawPayload, DindiProvider provider, String userId, String userName) {
    if (_isProcessing) return;
    _isProcessing = true;

    final dindiId = DindiQrParser.parseJoinPayload(rawPayload);

    if (dindiId == null) {
      _isProcessing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Dindi QR code. Please scan an official Dindi registration QR.'),
          backgroundColor: WariColors.danger,
        ),
      );
      return;
    }

    final dindi = provider.dindis.firstWhere(
      (d) => d.id == dindiId,
      orElse: () => provider.dindis.isNotEmpty ? provider.dindis.first : MockDindiData.dindis.first,
    );

    final isAlreadyMember = provider.hasJoinedDindi && provider.currentDindi?.id == dindi.id;

    showDialog(
      context: context,
      builder: (dlgContext) => DindiJoinConfirmationDialog(
        dindi: dindi,
        isAlreadyMember: isAlreadyMember,
        onConfirmJoin: () async {
          final success = await provider.joinDindi(dindi.id, userId, userName: userName);
          if (mounted && success) {
            Navigator.pushReplacementNamed(context, AppRoutes.dindiPass);
          }
        },
      ),
    ).then((_) {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<DindiProvider>(
      create: (_) => DindiProvider(
        repository: DindiRepository(apiService),
      )..loadDindis(),
      child: Consumer<DindiProvider>(
        builder: (context, provider, _) {
          final userProvider = Provider.of<UserProvider>(context);
          final user = userProvider.currentUser;

          return Scaffold(
            backgroundColor: WariColors.background,
            appBar: AppBar(
              title: const Text('Join Dindi (दिंडीत सामील व्हा)'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                children: [
                  // Camera Viewfinder Box
                  Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                      border: Border.all(color: WariColors.primary, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder Frame Corners
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: WariColors.accent, width: 2),
                            borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                          ),
                          child: const Center(
                            child: Icon(Icons.qr_code_scanner, color: WariColors.accent, size: 64),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                            ),
                            child: Text(
                              'Position QR code inside box',
                              style: WariTypography.labelSmall.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  Text(
                    'Scan the official QR code displayed by your Dindi leader (दिंडी प्रमुखांचा QR स्कॅन करा)',
                    style: WariTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: WariSpacing.base),

                  // Quick Demo Dindi QR Trigger Buttons
                  WariCard(
                    borderColor: WariColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.touch_app, color: WariColors.primary, size: 20),
                            const SizedBox(width: WariSpacing.xs),
                            Text('Instant Demo QR Selectors', style: WariTypography.titleMedium),
                          ],
                        ),
                        const SizedBox(height: WariSpacing.xs),
                        Text(
                          'Tap any official Dindi below to simulate instant QR code detection:',
                          style: WariTypography.caption,
                        ),
                        const SizedBox(height: WariSpacing.sm),

                        Wrap(
                          spacing: WariSpacing.xs,
                          runSpacing: WariSpacing.xs,
                          children: provider.dindis.map((dindi) {
                            return ChoiceChip(
                              label: Text(dindi.name, style: WariTypography.caption),
                              selected: false,
                              selectedColor: WariColors.primaryLight,
                              onSelected: (_) {
                                final payload = DindiQrParser.generateJoinPayload(dindi.id);
                                _handlePayloadScanned(
                                  payload,
                                  provider,
                                  user?.userId ?? 'varkari-001',
                                  user?.displayName ?? 'Pilgrim',
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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
