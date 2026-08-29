import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/sos_provider.dart';

/// Card displaying offline mesh network relay simulation steps.
class OfflineRelayCard extends StatelessWidget {
  const OfflineRelayCard({super.key});

  static const List<({String icon, String label, String sublabel})> _relayNodes = [
    (icon: '📱', label: 'Your Device', sublabel: 'Varkari'),
    (icon: '📡', label: 'Node-001', sublabel: 'Relay Node 1'),
    (icon: '📡', label: 'Node-003', sublabel: 'Relay Node 2'),
    (icon: '🏗️', label: 'Gateway', sublabel: 'LoRa Gateway'),
    (icon: '🖥️', label: 'Server', sublabel: 'WariVerse AI'),
  ];

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);
    final currentStep = sosProvider.relayStep;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(WariSpacing.base),
            decoration: BoxDecoration(
              color: WariColors.warningLight,
              borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
              border: Border.all(color: WariColors.warning, width: 2),
            ),
            child: Column(
              children: [
                const Text('📡', style: TextStyle(fontSize: 44)),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'OFFLINE SOS QUEUED',
                  style: WariTypography.headlineSmall.copyWith(color: WariColors.warningDark),
                ),
                Text(
                  'Activating peer-to-peer mesh relay network (LoRa / Bluetooth simulation)',
                  style: WariTypography.bodySmall.copyWith(color: WariColors.warningDark),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          WariCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔗 Mesh Relay Network Simulation', style: WariTypography.titleSmall),
                    const WariStatusChip(
                      label: 'DEMO MODE',
                      color: WariColors.warning,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.base),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _relayNodes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final node = entry.value;
                      final isPassed = currentStep > idx;
                      final isCurrent = currentStep == idx;

                      return Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPassed
                                      ? WariColors.successLight
                                      : (isCurrent ? WariColors.warningLight : WariColors.slate100),
                                  border: Border.all(
                                    color: isPassed
                                        ? WariColors.success
                                        : (isCurrent ? WariColors.warning : WariColors.border),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(node.icon, style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(node.label, style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                              Text(node.sublabel, style: WariTypography.caption.copyWith(fontSize: 9, color: WariColors.textMuted)),
                              if (isPassed)
                                Text('✓ OK', style: WariTypography.caption.copyWith(fontSize: 9, color: WariColors.success, fontWeight: FontWeight.bold))
                              else if (isCurrent)
                                Text('⏳ Sending...', style: WariTypography.caption.copyWith(fontSize: 9, color: WariColors.warningDark, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (idx < _relayNodes.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: isPassed ? WariColors.success : WariColors.border,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                if (currentStep >= 4) ...[
                  const SizedBox(height: WariSpacing.base),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(WariSpacing.sm),
                    decoration: BoxDecoration(
                      color: WariColors.successLight,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        '✅ SOS Delivered via Mesh Relay Network!',
                        style: WariTypography.labelSmall.copyWith(
                          color: WariColors.successDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          WariSecondaryButton(
            label: 'Back to SOS',
            onPressed: () => sosProvider.resetToIdle(),
          ),
        ],
      ),
    );
  }
}
