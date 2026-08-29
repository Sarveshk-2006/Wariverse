import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/qr_provider.dart';
import '../../../providers/user_provider.dart';
import 'wari_qr_result_dialog.dart';

/// Camera-based QR Scanner Screen with Realtime Cloud Firestore Token Validation.
class WariQrScannerModal extends StatefulWidget {
  const WariQrScannerModal({
    super.key,
    this.title = 'WariVerse QR Scanner',
    this.subtitle = 'Align QR code inside camera frame to validate',
    this.expectedType,
    this.onValidScan,
  });

  final String title;
  final String subtitle;
  final QrType? expectedType;
  final void Function(WariQrCode qrCode, Map<String, dynamic>? data)? onValidScan;

  @override
  State<WariQrScannerModal> createState() => _WariQrScannerModalState();
}

class _WariQrScannerModalState extends State<WariQrScannerModal> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualTokenController = TextEditingController();

  bool _isProcessing = false;
  QrScanResult? _scanResult;
  String? _statusMessage;
  WariQrCode? _validatedQr;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    await _processToken(rawValue.trim());
  }

  Future<void> _processToken(String token) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Validating token against Cloud Firestore authority...';
    });

    final cleanToken = WariQrCode.parseTokenFromRawPayload(token);
    final qrProvider = Provider.of<QrProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUid = userProvider.currentUser?.userId ?? 'anonymous_scanner';

    final validation = await qrProvider.validateScannedToken(
      rawToken: cleanToken,
      scannerUid: currentUid,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _scanResult = validation.result;
      _statusMessage = validation.message;
      _validatedQr = validation.qrCode;
    });

    if (widget.onValidScan != null && validation.result == QrScanResult.QR_VALID && validation.qrCode != null) {
      widget.onValidScan!(validation.qrCode!, validation.qrCode!.metadata);
    }

    // Show Varkari Identity Verified Dialog
    showDialog(
      context: context,
      builder: (_) => WariQrResultDialog(
        qrCode: validation.qrCode,
        scanResult: validation.result,
        message: validation.message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: 8),
            color: WariColors.slate800,
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: WariColors.primaryLight, size: 18),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Camera Viewfinder Frame
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Viewfinder Alignment Overlay Frame
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: WariColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: WariColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: WariColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Center(
                      child: WariLoadingIndicator(message: 'Validating Token with Firebase...'),
                    ),
                  ),
              ],
            ),
          ),

          // Validation Result / Action Card
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              color: WariColors.slate800,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _scanResult == QrScanResult.QR_VALID
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _scanResult == QrScanResult.QR_VALID
                            ? WariColors.success
                            : WariColors.danger,
                        size: 24,
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _scanResult == QrScanResult.QR_VALID
                                ? WariColors.successLight
                                : WariColors.dangerLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_validatedQr != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Type: ${_validatedQr!.type.displayName} • Owner: ${_validatedQr!.ownerId}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: WariSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusMessage = null;
                              _scanResult = null;
                              _validatedQr = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WariColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Scan Another QR'),
                        ),
                      ),
                      const SizedBox(width: WariSpacing.xs),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Debug / Widget Testing Manual Input Bar
          Container(
            padding: const EdgeInsets.all(WariSpacing.sm),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualTokenController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Debug: Enter token (WVQ_...)',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_manualTokenController.text.trim().isNotEmpty) {
                      _processToken(_manualTokenController.text.trim());
                    }
                  },
                  child: const Text('Verify', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
