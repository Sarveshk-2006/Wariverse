import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../dindi/dindi_palkhi_voice_screen.dart';

/// Dindi Leader / Pramukh Operational Management Dashboard.
class DindiLeaderDashboard extends StatefulWidget {
  const DindiLeaderDashboard({super.key});

  @override
  State<DindiLeaderDashboard> createState() => _DindiLeaderDashboardState();
}

class _DindiLeaderDashboardState extends State<DindiLeaderDashboard> {
  final TextEditingController _announcementController = TextEditingController();
  final TextEditingController _meetingPointNameController = TextEditingController();

  @override
  void dispose() {
    _announcementController.dispose();
    _meetingPointNameController.dispose();
    super.dispose();
  }

  void _showPostAnnouncementDialog(BuildContext context, VirtualDindiProvider dindiProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.campaign_rounded, color: WariColors.primary),
            SizedBox(width: 8),
            Text('Post Dindi Announcement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Broadcast an urgent message or schedule update to all members of this Dindi.',
              style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
            ),
            const SizedBox(height: WariSpacing.sm),
            TextField(
              controller: _announcementController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Next tea halt at Alandi Gate 3 in 20 minutes. Gather near the Palkhi chariot.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final text = _announcementController.text.trim();
              if (text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              _announcementController.clear();
              Navigator.pop(ctx);

              await dindiProvider.sendLeaderBroadcast(text);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('📣 Announcement broadcasted to Dindi members in realtime!'),
                  backgroundColor: WariColors.success,
                ),
              );
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text('Broadcast Now'),
          ),
        ],
      ),
    );
  }

  void _showUpdateMeetingPointDialog(BuildContext context, VirtualDindiProvider dindiProvider) {
    final active = dindiProvider.activeDindi;
    if (active == null) return;
    _meetingPointNameController.text = active.meetingPointName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.add_location_alt_rounded, color: WariColors.primary),
            SizedBox(width: 8),
            Text('Update Meeting Point'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set current emergency reunification point for lost or separated Varkaris.',
              style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
            ),
            const SizedBox(height: WariSpacing.sm),
            TextField(
              controller: _meetingPointNameController,
              decoration: const InputDecoration(
                labelText: 'Meeting Point Landmark / Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _meetingPointNameController.text.trim();
              if (name.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);

              final center = dindiProvider.groupCenter;
              await dindiProvider.setReunificationPoint(
                lat: center?.latitude ?? active.meetingPointLat,
                lng: center?.longitude ?? active.meetingPointLng,
                name: name,
              );

              messenger.showSnackBar(
                SnackBar(
                  content: Text('📍 Meeting point updated to "$name"!'),
                  backgroundColor: WariColors.success,
                ),
              );
            },
            child: const Text('Update Location'),
          ),
        ],
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context, VirtualDindi dindi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dindi.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan QR Code or enter Join Code to enter Dindi roster:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.border),
              ),
              child: QrImageView(
                data: 'https://web-one-tau-17.vercel.app/join-dindi?code=${dindi.joinCode}',
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final dindi = dindiProvider.activeDindi;

    final members = dindiProvider.members;
    final totalCount = members.isNotEmpty ? members.length : (dindi?.activeMemberCount ?? 0);
    final safeCount = members.where((m) => m.separationState == SeparationState.SAFE).length;
    final alertCount = members.where((m) => m.separationState == SeparationState.SEPARATED || m.separationState == SeparationState.CRITICAL).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(WariSpacing.base),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [WariColors.primaryDark, WariColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dindi?.name ?? 'Virtual Dindi Operations',
                            style: WariTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: WariColors.success,
                            borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.sensors, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('LIVE BEACON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.xs),
                    Text(
                      'Join Code: ${dindi?.joinCode ?? "VDND-0000"} • Pramukh: ${userProvider.currentUser?.displayName ?? "Dindi Leader"}',
                      style: WariTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),

              // Operational Metrics Summary
              Row(
                children: [
                  Expanded(
                    child: WariCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Members', style: WariTypography.caption),
                          const SizedBox(height: 4),
                          Text('$totalCount Varkaris', style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: WariSpacing.sm),
                  Expanded(
                    child: WariCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Safe / Separated', style: WariTypography.caption),
                          const SizedBox(height: 4),
                          Text('$safeCount Safe / $alertCount Alert', style: WariTypography.headlineSmall.copyWith(fontSize: 14, color: alertCount > 0 ? WariColors.danger : WariColors.success)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.base),

              const SectionHeader(title: 'Leader Quick Action Controls'),
              const SizedBox(height: WariSpacing.xs),

              // Palkhi Voice Action Button
              ListTile(
                tileColor: WariColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WariSpacing.sm),
                  side: const BorderSide(color: WariColors.border),
                ),
                leading: const CircleAvatar(
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.record_voice_over_rounded, color: WariColors.primaryDark, size: 20),
                ),
                title: Text('Palkhi Voice Audio Broadcast', style: WariTypography.titleMedium),
                subtitle: const Text('Start live audio broadcast or play devotional abhangavali'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DindiPalkhiVoiceScreen(dindiId: dindi?.dindiId)),
                  );
                },
              ),
              const SizedBox(height: WariSpacing.xs),

              // Post Announcement Action Button
              ListTile(
                tileColor: WariColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WariSpacing.sm),
                  side: const BorderSide(color: WariColors.border),
                ),
                leading: const CircleAvatar(
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.campaign_rounded, color: WariColors.primaryDark, size: 20),
                ),
                title: Text('Post Dindi Announcement', style: WariTypography.titleMedium),
                subtitle: const Text('Broadcast verified schedule update or meeting point to members'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPostAnnouncementDialog(context, dindiProvider),
              ),
              const SizedBox(height: WariSpacing.xs),

              // Update Reunification Location
              ListTile(
                tileColor: WariColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WariSpacing.sm),
                  side: const BorderSide(color: WariColors.border),
                ),
                leading: const CircleAvatar(
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.add_location_alt_rounded, color: WariColors.primaryDark, size: 20),
                ),
                title: Text('Update Reunification Meeting Point', style: WariTypography.titleMedium),
                subtitle: Text('Current: ${dindi?.meetingPointName ?? "Palkhi Rest Area"}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUpdateMeetingPointDialog(context, dindiProvider),
              ),
              const SizedBox(height: WariSpacing.xs),

              // Digital Pass / QR Code
              ListTile(
                tileColor: WariColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WariSpacing.sm),
                  side: const BorderSide(color: WariColors.border),
                ),
                leading: const CircleAvatar(
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.qr_code_2_rounded, color: WariColors.primaryDark, size: 20),
                ),
                title: Text('Generate Digital Dindi Join Pass', style: WariTypography.titleMedium),
                subtitle: const Text('Display QR code for new Varkaris to join Dindi roster'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (dindi != null) _showQrCodeDialog(context, dindi);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
