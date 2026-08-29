import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/sos_provider.dart';
import 'emergency_contacts_widget.dart';

/// Primary idle view for SOS emergency trigger with 2-second hold evidence recording & WoShield2 features.
class SosIdleView extends StatefulWidget {
  const SosIdleView({super.key});

  @override
  State<SosIdleView> createState() => _SosIdleViewState();
}

class _SosIdleViewState extends State<SosIdleView> {
  final _voiceSearchController = TextEditingController();

  @override
  void dispose() {
    _voiceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        children: [
          const SizedBox(height: WariSpacing.xs),
          Text(
            'Emergency Help is One Tap Away',
            style: WariTypography.titleMedium.copyWith(color: WariColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WariSpacing.md),

          // Big Emergency SOS Button (Supports 2-second hold for Evidence Recording)
          Center(
            child: GestureDetector(
              onLongPress: () {
                sosProvider.start2SecondHoldEmergencyRecording();
              },
              child: SosButton(
                size: 135,
                label: sosProvider.isRecordingEvidence ? 'RECORDING' : 'SOS',
                onPressed: () => sosProvider.setUiState(SosUiState.confirming),
              ),
            ),
          ),
          const SizedBox(height: WariSpacing.sm),

          // Evidence Recording Progress Banner
          if (sosProvider.isRecordingEvidence) ...[
            Container(
              padding: const EdgeInsets.all(WariSpacing.sm),
              decoration: BoxDecoration(
                color: WariColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.danger),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.videocam_rounded, color: WariColors.danger, size: 20),
                      SizedBox(width: 6),
                      Text('Capturing 10s Emergency Evidence Recording...', style: TextStyle(fontWeight: FontWeight.bold, color: WariColors.danger, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: sosProvider.recordingProgressSeconds / 10.0,
                    backgroundColor: WariColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(WariColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.sm),
          ],

          Text(
            'Tap for instant SOS. Hold button for 2 seconds to capture evidence recording.',
            style: WariTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WariSpacing.base),

          // Voice Threat AI Analysis Bar (Ported from WoShield2 SurakshaVoiceAI)
          WariCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.record_voice_over_rounded, color: WariColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text('Voice Threat AI Detector (SurakshaVoiceAI)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Speaks phrases like "Help", "Bachao", "Doctor", "Police", "Stampede" for automated emergency trigger.',
                  style: TextStyle(fontSize: 10, color: WariColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voiceSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Speak or type spoken text...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WariColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        final text = _voiceSearchController.text.trim();
                        if (text.isNotEmpty) {
                          sosProvider.analyzeVoiceThreatText(text);
                          _voiceSearchController.clear();
                        }
                      },
                      child: const Text('Analyze AI', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

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
          const SizedBox(height: WariSpacing.base),

          // Emergency Contacts Management & Automated SMS Dispatch
          const EmergencyContactsWidget(),

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
