import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/utils/virtual_dindi_engine.dart';
import '../../models/models_exports.dart';
import '../../providers/virtual_dindi_provider.dart';

class VirtualDindiDetailScreen extends StatefulWidget {
  const VirtualDindiDetailScreen({super.key});

  @override
  State<VirtualDindiDetailScreen> createState() => _VirtualDindiDetailScreenState();
}

class _VirtualDindiDetailScreenState extends State<VirtualDindiDetailScreen> {
  final _broadcastController = TextEditingController();
  final _meetingNameController = TextEditingController();

  void _showQrCodeDialog(VirtualDindi dindi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dindi.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan QR or enter Join Code to join this Dindi', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.border),
              ),
              child: QrImageView(
                data: dindi.qrToken,
                version: QrVersions.auto,
                size: 180,
                gapless: true,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              dindi.joinCode,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: WariColors.primary, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(VirtualDindiProvider provider, VirtualDindiMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.displayName} from this Virtual Dindi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WariColors.danger),
            onPressed: () {
              provider.removeMember(member.uid);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.displayName} removed from Dindi.')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(VirtualDindiProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Group Broadcast'),
        content: TextField(
          controller: _broadcastController,
          decoration: const InputDecoration(
            hintText: 'e.g. Return to Dindi / Gathering at Palkhi halt point now',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_broadcastController.text.trim().isNotEmpty) {
                provider.sendLeaderBroadcast(
                  title: 'Group Broadcast',
                  message: _broadcastController.text.trim(),
                  type: 'ANNOUNCEMENT',
                );
                _broadcastController.clear();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Broadcast sent to Dindi members!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showMeetingPointDialog(VirtualDindiProvider provider) {
    final center = provider.groupCenter;
    final lat = center?.latitude ?? 18.5204;
    final lng = center?.longitude ?? 73.8567;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Reunification Point'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a recommended meeting point for separated members:'),
            const SizedBox(height: WariSpacing.xs),
            TextField(
              controller: _meetingNameController,
              decoration: const InputDecoration(
                labelText: 'Meeting Point Name',
                hintText: 'e.g. Main Palkhi Mandap',
              ),
            ),
            const SizedBox(height: 8),
            Text('Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}', style: const TextStyle(fontSize: 11, color: WariColors.textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = _meetingNameController.text.trim().isEmpty ? 'Main Palkhi Mandap' : _meetingNameController.text.trim();
              provider.setReunificationPoint(lat: lat, lng: lng, name: name);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reunification point updated to "$name"')),
              );
            },
            child: const Text('Save Point'),
          ),
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
        appBar: AppBar(title: const Text('Virtual Dindi')),
        body: const Center(child: Text('No active Virtual Dindi session.')),
      );
    }

    final members = dindiProvider.members;
    final isLeader = dindiProvider.isLeader;
    final state = dindiProvider.currentSeparationState;
    final dist = dindiProvider.distanceFromGroupMeters.toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(dindi.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => _showQrCodeDialog(dindi),
            tooltip: 'View Dindi QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: WariColors.danger),
            onPressed: () async {
              final nav = Navigator.of(context);
              await dindiProvider.leaveVirtualDindi();
              nav.pop();
            },
            tooltip: 'Leave Dindi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Real-Time Member Separation Alert Banner
            if (dindiProvider.hasSeparationAlert)
              Container(
                margin: const EdgeInsets.only(bottom: WariSpacing.md),
                padding: const EdgeInsets.all(WariSpacing.md),
                decoration: BoxDecoration(
                  color: WariColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(WariSpacing.md),
                  border: Border.all(color: WariColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: WariColors.danger, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠ MEMBER SEPARATED (${dindiProvider.separatedMembers.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.danger),
                          ),
                          Text(
                            '${dindiProvider.separatedMembers.map((m) => m.displayName).join(", ")} separated from group boundary.',
                            style: const TextStyle(fontSize: 11, color: WariColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Status & Info Header Card
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.surface,
                borderRadius: BorderRadius.circular(WariSpacing.md),
                border: Border.all(color: WariColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Join Code: ${dindi.joinCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Chip(
                        label: Text(dindi.status.name, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: dindi.status == VirtualDindiStatus.ACTIVE ? WariColors.success : WariColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Leader: ${dindi.leaderName}', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                  Text('Safe Radius: ${dindi.safeRadiusMeters.toInt()}m | Separation Threshold: ${dindi.separationThresholdMeters.toInt()}m', style: const TextStyle(fontSize: 11, color: WariColors.textMuted)),
                  const SizedBox(height: WariSpacing.xs),
                  Text('Your Distance to Group: ${dist}m (${state.displayName})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.md),

            // Leader Control Panel
            if (isLeader) ...[
              const Text('Leader Control Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: WariSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => dindiProvider.setDindiStatus(
                        dindi.status == VirtualDindiStatus.ACTIVE ? VirtualDindiStatus.PAUSED : VirtualDindiStatus.ACTIVE,
                      ),
                      icon: Icon(dindi.status == VirtualDindiStatus.ACTIVE ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 16),
                      label: Text(dindi.status == VirtualDindiStatus.ACTIVE ? 'Pause Travel' : 'Resume Travel', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMeetingPointDialog(dindiProvider),
                      icon: const Icon(Icons.flag_rounded, size: 16),
                      label: const Text('Set Meeting Point', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showBroadcastDialog(dindiProvider),
                      icon: const Icon(Icons.campaign_rounded, size: 16),
                      label: const Text('Broadcast', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.md),
            ],

            // Reunification Meeting Point Card
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(WariSpacing.md),
                border: Border.all(color: WariColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: WariColors.primary, size: 28),
                  const SizedBox(width: WariSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reunification Meeting Point', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WariColors.textSecondary)),
                        Text(dindi.meetingPointName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('GPS: ${dindi.meetingPointLat.toStringAsFixed(4)}, ${dindi.meetingPointLng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: WariColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.md),

            // Live Member Roster
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dindi Members (${members.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  dindiProvider.networkStatus == DindiNetworkStatus.LIVE ? '🟢 Realtime Stream' : '🟡 Offline Local Mode',
                  style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final m = members[i];

                Color badgeColor;
                switch (m.separationState) {
                  case SeparationState.SAFE: badgeColor = WariColors.success; break;
                  case SeparationState.CAUTION: badgeColor = WariColors.warning; break;
                  case SeparationState.SEPARATED: badgeColor = WariColors.crowdOrange; break;
                  case SeparationState.CRITICAL: badgeColor = WariColors.danger; break;
                  case SeparationState.RETURNING: badgeColor = WariColors.info; break;
                }

                return ListTile(
                  tileColor: WariColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WariSpacing.sm),
                    side: const BorderSide(color: WariColors.border),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: badgeColor.withValues(alpha: 0.15),
                    child: Icon(
                      m.isLeader ? Icons.star_rounded : Icons.person_rounded,
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (m.isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: WariColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: const Text('LEADER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${VirtualDindiEngine.formatDistance(m.distanceFromGroupMeters)} • ${m.trend.displayName} • GPS ±${m.accuracyMeters.toInt()}m',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: badgeColor),
                        ),
                        child: Text(
                          m.separationState.name,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                      if (isLeader && !m.isLeader) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.person_remove_rounded, color: WariColors.danger, size: 18),
                          onPressed: () => _showRemoveMemberDialog(dindiProvider, m),
                          tooltip: 'Remove Member',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
