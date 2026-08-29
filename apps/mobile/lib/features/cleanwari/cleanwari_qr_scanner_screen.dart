import 'package:flutter/material.dart';
import '../../navigation/app_routes.dart';
import '../../services/cleanwari_qr_parser.dart';
import '../qr/widgets/wari_qr_scanner_modal.dart';

/// QR Code scanner screen for CleanWari smart toilet reporting using real Android camera.
class CleanWariQrScannerScreen extends StatelessWidget {
  const CleanWariQrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WariQrScannerModal(
      title: 'CleanWari Toilet QR Scanner',
      subtitle: 'Align toilet QR tag inside camera frame to report hygiene',
      onValidScan: (qrCode, metadata) {
        final toiletId = CleanWariQrParser.parseToiletPayload(qrCode.token) ??
            (qrCode.targetDocumentId.isNotEmpty ? qrCode.targetDocumentId : 'toilet-001');

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.cleanWariReport,
          arguments: {
            'toiletId': toiletId,
            'toiletQrCode': qrCode.token,
            'toiletName': metadata?['name'] ?? 'Toilet Facility #$toiletId',
          },
        );
      },
    );
  }
}
