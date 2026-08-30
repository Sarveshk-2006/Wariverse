import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/wari_theme_exports.dart';
import 'status_chip.dart';
import '../../models/qr_code_model.dart';

/// Production Card Widget rendering genuine high-resolution QR bitmaps with quiet zone, token info, and action controls.
class WariQrCard extends StatelessWidget {
  const WariQrCard({
    super.key,
    required this.qrCode,
    this.title,
    this.subtitle,
    this.size = 180.0,
    this.onRegenerate,
    this.onRevoke,
    this.onPrintShare,
  });

  final WariQrCode qrCode;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRevoke;
  final VoidCallback? onPrintShare;

  @override
  Widget build(BuildContext context) {
    final isRevoked = qrCode.status == QrStatus.REVOKED;
    final isExpired = qrCode.status == QrStatus.EXPIRED;

    return Container(
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.lg),
        border: Border.all(
          color: isRevoked ? WariColors.danger : WariColors.border,
          width: isRevoked ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header / Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title ?? qrCode.type.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WariColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              WariStatusChip(
                label: qrCode.status.name,
                color: isRevoked
                    ? WariColors.danger
                    : (isExpired ? WariColors.warning : WariColors.success),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: WariSpacing.md),

          // Real QR Bitmap Container with Quiet Zone
          Container(
            padding: const EdgeInsets.all(WariSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(WariSpacing.md),
              border: Border.all(color: WariColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: isRevoked
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.2,
                        child: QrImageView(
                          data: qrCode.formattedQrPayload,
                          version: QrVersions.auto,
                          size: size,
                          gapless: true,
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, color: WariColors.danger, size: 48),
                          SizedBox(height: 4),
                          Text(
                            'QR REVOKED',
                            style: TextStyle(
                              color: WariColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : QrImageView(
                    data: qrCode.formattedQrPayload,
                    version: QrVersions.auto,
                    size: size,
                    gapless: true,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: WariColors.slate900,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: WariColors.slate900,
                    ),
                  ),
          ),
          const SizedBox(height: WariSpacing.md),

          // Token Identifier Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: WariColors.background,
              borderRadius: BorderRadius.circular(WariSpacing.sm),
              border: Border.all(color: WariColors.border),
            ),
            child: SelectableText(
              'WARI ID: ${qrCode.shortDisplayId}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: WariColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'Scans: ${qrCode.scanCount} ${qrCode.lastScannedAt != null ? '• Last: ${_formatAge(qrCode.lastScannedAt!)}' : ''}',
            style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
          ),
          const SizedBox(height: WariSpacing.md),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPrintShare != null && !isRevoked) ...[
                OutlinedButton.icon(
                  onPressed: onPrintShare,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share / Print', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: WariSpacing.xs),
              ],
              if (onRegenerate != null) ...[
                OutlinedButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: WariSpacing.xs),
              ],
              if (onRevoke != null && !isRevoked)
                IconButton(
                  tooltip: 'Revoke QR',
                  icon: const Icon(Icons.delete_outline_rounded, color: WariColors.danger, size: 20),
                  onPressed: onRevoke,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatAge(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return isoStr;
    }
  }
}
