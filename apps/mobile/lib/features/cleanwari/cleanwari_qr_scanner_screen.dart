import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';
import '../../services/cleanwari_qr_parser.dart';

/// QR Code scanner screen for CleanWari smart toilet reporting.
class CleanWariQrScannerScreen extends StatefulWidget {
  const CleanWariQrScannerScreen({super.key});

  @override
  State<CleanWariQrScannerScreen> createState() => _CleanWariQrScannerScreenState();
}

class _CleanWariQrScannerScreenState extends State<CleanWariQrScannerScreen> {
  String? _errorMessage;

  void _onScanQr(String rawPayload, String name) {
    setState(() => _errorMessage = null);
    final toiletId = CleanWariQrParser.parseToiletPayload(rawPayload);

    if (toiletId == null) {
      setState(() => _errorMessage = 'Invalid CleanWari QR code scanned.');
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.cleanWariReport,
      arguments: {
        'toiletId': toiletId,
        'toiletQrCode': rawPayload,
        'toiletName': name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('CleanWari QR Scanner (स्वच्छवारी)'),
      ),
      body: Column(
        children: [
          const OfflineBanner(message: 'Demo Mode — Select official toilet QR code below'),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: WariCard(
                borderColor: WariColors.danger,
                child: Text(_errorMessage!, style: WariTypography.bodyMedium.copyWith(color: WariColors.danger)),
              ),
            ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(WariSpacing.xl),
              decoration: BoxDecoration(
                border: Border.all(color: WariColors.primary, width: 3),
                borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                color: Colors.black26,
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: WariColors.primary, size: 80),
                    SizedBox(height: WariSpacing.base),
                    Text(
                      'Align QR code inside frame to report cleanliness',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Demo QR Selector Chips
          Container(
            padding: const EdgeInsets.all(WariSpacing.base),
            color: WariColors.slate800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEMO TOILET QR SELECTOR (क्यूआर निवडा)',
                  style: WariTypography.labelSmall.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: WariSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _onScanQr(
                          'cleanwari:toilet:toilet-001',
                          'Pandharpur Route — Halt 03',
                        ),
                        icon: const Icon(Icons.wc, size: 16),
                        label: const Text('Toilet #01 (Halt 03)'),
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      ElevatedButton.icon(
                        onPressed: () => _onScanQr(
                          'cleanwari:toilet:toilet-002',
                          'Hadapsar Seva Pandal #5',
                        ),
                        icon: const Icon(Icons.wc, size: 16),
                        label: const Text('Toilet #02 (Hadapsar)'),
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      ElevatedButton.icon(
                        onPressed: () => _onScanQr(
                          'cleanwari:toilet:toilet-003',
                          'Saswad Ringan Ground Facility',
                        ),
                        icon: const Icon(Icons.wc, size: 16),
                        label: const Text('Toilet #03 (Saswad)'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
