import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/sos_provider.dart';

/// Primary idle view for one-tap SOS emergency trigger.
class SosIdleView extends StatelessWidget {
  const SosIdleView({super.key});

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        children: [
          const SizedBox(height: WariSpacing.base),
          Text(
            'Emergency Help is One Tap Away',
            style: WariTypography.titleMedium.copyWith(color: WariColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WariSpacing.lg),

          // Big Emergency SOS Button
          Center(
            child: SosButton(
              size: 130,
              label: 'SOS',
              onPressed: () => sosProvider.setUiState(SosUiState.confirming),
            ),
          ),
          const SizedBox(height: WariSpacing.base),
          Text(
            'Press for emergency medical, police, or rescue assistance',
            style: WariTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WariSpacing.xl),

          // Category Quick Selector
          WariCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Select Emergency Type',
                  subtitle: 'Quickly categorize your request before sending',
                ),
                const SizedBox(height: WariSpacing.sm),
                Wrap(
                  spacing: WariSpacing.xs,
                  runSpacing: WariSpacing.xs,
                  children: SOSCategory.values.map((cat) {
                    final isSelected = sosProvider.selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        sosProvider.setSelectedCategory(cat);
                        sosProvider.setUiState(SosUiState.confirming);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? WariColors.danger : WariColors.slate100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getCategoryEmoji(cat)),
                            const SizedBox(width: 4),
                            Text(
                              cat.displayName,
                              style: WariTypography.labelSmall.copyWith(
                                color: isSelected ? Colors.white : WariColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Offline Queue Status Card
          if (sosProvider.offlineQueue.isNotEmpty) ...[
            const SizedBox(height: WariSpacing.base),
            WariCard(
              borderColor: WariColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_off, color: WariColors.warning, size: 18),
                      const SizedBox(width: WariSpacing.xs),
                      Text(
                        'Offline SOS Queue (${sosProvider.offlineQueue.length})',
                        style: WariTypography.titleSmall.copyWith(color: WariColors.warningDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: WariSpacing.xs),
                  Text(
                    'Queued requests will automatically sync when back online.',
                    style: WariTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _getCategoryEmoji(SOSCategory cat) {
    switch (cat) {
      case SOSCategory.MEDICAL: return '🏥';
      case SOSCategory.ACCIDENT: return '🚨';
      case SOSCategory.LOST: return '👤';
      case SOSCategory.WOMEN_SAFETY: return '🆘';
      case SOSCategory.CHILD: return '👶';
      case SOSCategory.DEHYDRATION: return '💧';
      case SOSCategory.FATIGUE: return '😓';
      case SOSCategory.OTHER: return '❓';
    }
  }
}
