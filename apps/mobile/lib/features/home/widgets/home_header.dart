import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/home_provider.dart';

/// Top header section for Home Dashboard.
/// Displays devotional greeting, user name, weather badge, and digital Pilgrim e-ID button.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final user = userProvider.currentUser;
    final weather = homeProvider.weather;

    return Column(
      children: [
        WariCard(
          color: WariColors.surface,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Saffron Devotional Icon Flag
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: WariColors.primary,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: WariColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🚩', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: WariSpacing.md),
                  // Devotional Greeting & User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'राम कृष्ण हरी 🙏',
                          style: WariTypography.headlineSmall.copyWith(
                            color: WariColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Welcome, ${user?.displayName ?? "Pilgrim"} · Pandharpur Wari',
                          style: WariTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Weather Snippet
                  if (weather != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WariSpacing.sm,
                        vertical: WariSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: WariColors.slate100,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${weather.temperatureC.toStringAsFixed(1)}°C',
                            style: WariTypography.labelLarge.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            weather.condition,
                            style: WariTypography.caption.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: WariSpacing.md),
              const Divider(),
              const SizedBox(height: WariSpacing.xs),
              // e-ID QR Button bar
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
        ),
      ],
    );
  }

  void _showQrModal(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(WariSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Digital Pilgrim ID', style: WariTypography.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.sm),
              Text(
                'Scan this QR code to verify identity or access emergency contacts.',
                style: WariTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.base),
              Container(
                padding: const EdgeInsets.all(WariSpacing.base),
                decoration: BoxDecoration(
                  color: WariColors.slate50,
                  borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                  border: Border.all(color: WariColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 160, color: WariColors.textPrimary),
                    const SizedBox(height: WariSpacing.sm),
                    Text(
                      'WariVerse pilgrim:$userId',
                      style: WariTypography.caption.copyWith(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),
              WariPrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
