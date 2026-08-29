import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/user_provider.dart';

/// Modal dialog displaying verified Varkari QR Identity & Profile Details with role-based PII shielding.
class WariQrResultDialog extends StatefulWidget {
  const WariQrResultDialog({
    super.key,
    required this.qrCode,
    required this.scanResult,
    required this.message,
  });

  final WariQrCode? qrCode;
  final QrScanResult scanResult;
  final String message;

  @override
  State<WariQrResultDialog> createState() => _WariQrResultDialogState();
}

class _WariQrResultDialogState extends State<WariQrResultDialog> {
  bool _isLoadingProfile = true;
  Map<String, dynamic>? _profileData;
  bool _showEmergencyInfo = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.qrCode == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.qrCode!.ownerId)
          .get();

      if (mounted) {
        setState(() {
          _profileData = doc.exists ? doc.data() : null;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.currentRole;
    final isAuthorizedForEmergency = userRole == UserRole.POLICE ||
        userRole == UserRole.MEDICAL_TEAM ||
        userRole == UserRole.ADMIN;

    final isValid = widget.scanResult == QrScanResult.QR_VALID && widget.qrCode != null;

    final name = _profileData?['full_name'] as String? ??
        widget.qrCode?.metadata?['title'] as String? ??
        'Wari Pilgrim';
    final phone = _profileData?['phone'] as String? ?? 'Protected';
    final age = _profileData?['age'];
    final bloodGroup = _profileData?['blood_group'] as String? ?? 'O+';
    final roleName = _profileData?['role'] as String? ?? widget.qrCode?.type.displayName ?? 'VARKARI';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Icon
            Row(
              children: [
                Icon(
                  isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  color: isValid ? WariColors.success : WariColors.danger,
                  size: 32,
                ),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    isValid ? 'Wari Identity Verified' : 'QR Verification Failed',
                    style: WariTypography.headlineSmall.copyWith(
                      color: isValid ? WariColors.successDark : WariColors.dangerDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            if (!isValid) ...[
              Container(
                padding: const EdgeInsets.all(WariSpacing.md),
                decoration: BoxDecoration(
                  color: WariColors.dangerLight,
                  borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(color: WariColors.dangerDark, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: WariSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: WariColors.danger, foregroundColor: Colors.white),
                child: const Text('Dismiss'),
              ),
            ] else ...[
              if (_isLoadingProfile)
                const Padding(
                  padding: EdgeInsets.all(WariSpacing.lg),
                  child: Center(child: WariLoadingIndicator(message: 'Fetching Varkari Registry Profile...')),
                )
              else ...[
                WariCard(
                  color: WariColors.slate50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: WariTypography.titleLarge.copyWith(color: WariColors.primaryDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: WariColors.successLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: WariTypography.labelSmall.copyWith(color: WariColors.successDark, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Wari Safe ID: ${widget.qrCode!.shortDisplayId}', style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.primary, fontSize: 13)),
                      const SizedBox(height: WariSpacing.xs),
                      Text('Role: $roleName • Scans: ${widget.qrCode!.scanCount}', style: WariTypography.bodySmall),
                      const Divider(height: 20),
                      Row(
                        children: [
                          if (age != null && age != 0) ...[
                            const Icon(Icons.cake, size: 16, color: WariColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Age: $age yrs', style: WariTypography.bodySmall),
                            const SizedBox(width: 16),
                          ],
                          const Icon(Icons.bloodtype, size: 16, color: WariColors.danger),
                          const SizedBox(width: 4),
                          Text('Blood: $bloodGroup', style: WariTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.base),

                // Privacy Shield Emergency Info Section
                Container(
                  padding: const EdgeInsets.all(WariSpacing.md),
                  decoration: BoxDecoration(
                    color: isAuthorizedForEmergency ? WariColors.warningLight.withValues(alpha: 0.3) : WariColors.slate100,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                    border: Border.all(
                      color: isAuthorizedForEmergency ? WariColors.warning : WariColors.slate300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAuthorizedForEmergency ? Icons.security_rounded : Icons.lock_rounded,
                            size: 18,
                            color: isAuthorizedForEmergency ? WariColors.warningDark : WariColors.slate600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAuthorizedForEmergency ? 'Emergency Contacts (Authorized)' : 'Private Emergency Info Protected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAuthorizedForEmergency ? WariColors.warningDark : WariColors.slate700,
                            ),
                          ),
                        ],
                      ),
                      if (isAuthorizedForEmergency) ...[
                        const SizedBox(height: 8),
                        if (_showEmergencyInfo) ...[
                          Text('Primary Phone: $phone', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Owner UID: ${widget.qrCode!.ownerId}', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                        ] else
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _showEmergencyInfo = true),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Emergency Phone'),
                          ),
                      ] else ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Phone numbers & sensitive medical contact info are protected and restricted to Police, Medical & Admin personnel.',
                          style: TextStyle(fontSize: 11, color: WariColors.slate600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: WariSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary, foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
