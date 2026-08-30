import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/virtual_dindi_provider.dart';
import 'dindi_palkhi_voice_screen.dart';
import 'dindi_community_screen.dart';
import 'widgets/dindi_audio_player_widget.dart';

/// "MY DINDI" Tab — Procession & Group Overview Screen.
/// Focuses purely on Dindi identity, checkpoints, schedule, announcements, and separation metrics.
/// Does NOT render full member roster list.
class VirtualDindiOverviewScreen extends StatelessWidget {
  const VirtualDindiOverviewScreen({super.key});

  void _showQrCodeDialog(BuildContext context, VirtualDindi dindi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dindi.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan QR Code or use Join Code to enter Dindi roster:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.border),
              ),
              child: QrImageView(
                data: 'VARKARI DINDI JOIN CODE: ${dindi.joinCode}\nNAME: ${dindi.name}\nLEADER: ${dindi.leaderName}',
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'JOIN CODE: ${dindi.joinCode}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: WariColors.primaryDark),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final dindi = dindiProvider.activeDindi;

    if (dindi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Dindi Overview')),
        body: const Center(
          child: WariEmptyState(
            icon: Icons.groups_outlined,
            title: 'No Active Virtual Dindi',
            subtitle: 'Join an existing Dindi using a code/QR or create a new Dindi.',
          ),
        ),
      );
    }

    final members = dindiProvider.members;
    final totalCount = members.isNotEmpty ? members.length : dindi.activeMemberCount;
    final safeCount = members.where((m) => m.separationState == SeparationState.SAFE).length;
    final cautionCount = members.where((m) => m.separationState == SeparationState.CAUTION).length;
    final alertCount = members.where((m) => m.separationState == SeparationState.SEPARATED || m.separationState == SeparationState.CRITICAL).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${dindi.name} — Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => _showQrCodeDialog(context, dindi),
            tooltip: 'Dindi Pass QR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DINDI IDENTITY CARD
            WariCard(
              borderColor: WariColors.primary.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dindi.name,
                          style: WariTypography.titleMedium.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                      WariStatusChip(
                        label: dindi.status.name,
                        color: WariColors.success,
                        dense: true,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildMetaRow(Icons.pin_outlined, 'Dindi Join Code', dindi.joinCode),
                  _buildMetaRow(Icons.person_outline, 'Dindi Leader / Pramukh', dindi.leaderName),
                  _buildMetaRow(Icons.meeting_room_outlined, 'Reunification Landmark', dindi.meetingPointName),
                  _buildMetaRow(Icons.access_time_rounded, 'Session Started', DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.tryParse(dindi.createdAt) ?? DateTime.now())),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // 2. SEPARATION METRICS SUMMARY
            Text('Separation Status Summary', style: WariTypography.titleSmall),
            const SizedBox(height: WariSpacing.xs),
            Row(
              children: [
                _buildMetricTile('Registered', '$totalCount', WariColors.primary),
                const SizedBox(width: 6),
                _buildMetricTile('Safe', '$safeCount', WariColors.success),
                const SizedBox(width: 6),
                _buildMetricTile('Caution', '$cautionCount', WariColors.warning),
                const SizedBox(width: 6),
                _buildMetricTile('Alert', '$alertCount', WariColors.danger),
              ],
            ),
            const SizedBox(height: WariSpacing.base),

            // 3. SCHEDULE & CHECKPOINT PROGRESS
            Text('Pilgrimage Route Checkpoint Schedule', style: WariTypography.titleSmall),
            const SizedBox(height: WariSpacing.xs),
            WariCard(
              child: Column(
                children: [
                  _buildCheckpointRow('Start Point', 'Alandi Sansthan Temple', '06:00 AM', isPassed: true),
                  const Divider(height: 12),
                  _buildCheckpointRow('Current Position', dindi.meetingPointName, 'Active', isCurrent: true),
                  const Divider(height: 12),
                  _buildCheckpointRow('Next Halt', 'Hadapsar Night Palkhi Rest', '07:30 PM', isUpcoming: true),
                  const Divider(height: 12),
                  _buildCheckpointRow('Final Destination', 'Pandharpur Vitthal Mandir', 'Day 21', isUpcoming: true),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // 4. ANNOUNCEMENTS & PALKHI VOICE ACCESS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('📢 Dindi Announcements & Broadcasts', style: WariTypography.titleSmall),
                if (dindiProvider.broadcasts.isNotEmpty)
                  WariStatusChip(label: '${dindiProvider.broadcasts.length} Broadcasts', color: WariColors.primary, dense: true),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            if (dindiProvider.broadcasts.isEmpty)
              WariCard(
                borderColor: WariColors.primary.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: WariColors.primary, size: 28),
                    const SizedBox(width: WariSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('No Announcements Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.primary)),
                          Text('New broadcasts from your Dindi Leader will appear here in real time.', style: TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...dindiProvider.broadcasts.map((b) => WariCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    borderColor: b.type == 'PALKHI_AUDIO' ? WariColors.primary.withValues(alpha: 0.3) : WariColors.border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            WariStatusChip(
                              label: b.type == 'PALKHI_AUDIO' ? '🔊 PALKHI AUDIO' : (b.type == 'ALERT' ? '⚠️ ALERT' : '📢 ANNOUNCEMENT'),
                              color: b.type == 'PALKHI_AUDIO' ? WariColors.primary : (b.type == 'ALERT' ? WariColors.danger : WariColors.info),
                              dense: true,
                            ),
                            Text(
                              DateFormat('hh:mm a').format(b.createdAt),
                              style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Leader: ${b.sender} • ${b.message}', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                        if (b.audioUrl != null && b.audioUrl!.isNotEmpty)
                          DindiAudioPlayerWidget(
                            audioUrl: b.audioUrl!,
                            title: b.title,
                          ),
                      ],
                    ),
                  )),
            const SizedBox(height: WariSpacing.base),

            // 5. QUICK ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showQrCodeDialog(context, dindi),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    label: const Text('Share Dindi Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DindiCommunityScreen(dindiId: dindi.dindiId)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.forum_rounded, color: Colors.white, size: 18),
                    label: const Text('Community Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DindiPalkhiVoiceScreen(dindiId: dindi.dindiId)),
                  );
                },
                icon: const Icon(Icons.record_voice_over_rounded, color: WariColors.primaryDark),
                label: const Text('Open Palkhi Voice Broadcast', style: TextStyle(fontWeight: FontWeight.bold, color: WariColors.primaryDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: WariColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: WariTypography.caption.copyWith(color: WariColors.textPrimary), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: WariColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointRow(String stage, String name, String time, {bool isPassed = false, bool isCurrent = false, bool isUpcoming = false}) {
    Color color = isCurrent ? WariColors.primary : (isPassed ? WariColors.success : WariColors.textMuted);
    return Row(
      children: [
        Icon(isCurrent ? Icons.radio_button_checked : Icons.check_circle_outline, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
              Text(stage, style: const TextStyle(fontSize: 10, color: WariColors.textMuted)),
            ],
          ),
        ),
        Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
