import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/dindi_repository.dart';
import '../../services/api_service.dart';
import '../../services/dindi_qr_parser.dart';
import '../../services/mock_dindi_data.dart';
import '../qr/widgets/wari_qr_scanner_modal.dart';
import 'dindi_join_confirmation_dialog.dart';

/// Interactive QR Scanner screen for joining a Dindi procession batch using real Android camera.
class DindiQrScannerScreen extends StatefulWidget {
  const DindiQrScannerScreen({super.key});

  @override
  State<DindiQrScannerScreen> createState() => _DindiQrScannerScreenState();
}

class _DindiQrScannerScreenState extends State<DindiQrScannerScreen> {
  bool _isProcessing = false;

  void _handleScan(String rawToken, BuildContext context, DindiProvider provider, String userId, String userName) {
    if (_isProcessing) return;
    _isProcessing = true;

    final dindiId = DindiQrParser.parseJoinPayload(rawToken) ??
        (rawToken.contains('dindi') ? rawToken.split('_').last : 'dindi-001');

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
          if (context.mounted && success) {
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

          return WariQrScannerModal(
            title: 'Join Dindi QR Scanner (दिंडी सामील व्हा)',
            subtitle: 'Align official Dindi QR tag inside camera frame to join',
            onValidScan: (qrCode, metadata) {
              _handleScan(
                qrCode.token,
                context,
                provider,
                user?.userId ?? 'varkari-001',
                user?.displayName ?? 'Pilgrim',
              );
            },
          );
        },
      ),
    );
  }
}
