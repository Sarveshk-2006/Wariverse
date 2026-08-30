import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import 'widgets/dindi_audio_player_widget.dart';

/// Unified Dual-Channel Dindi Communication Center (Official Announcements + Community General Chat).
/// Shared by both Dindi Leaders and Varkari Pilgrims with role-based write permissions.
class DindiCommunityScreen extends StatefulWidget {
  const DindiCommunityScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  State<DindiCommunityScreen> createState() => _DindiCommunityScreenState();
}

class _DindiCommunityScreenState extends State<DindiCommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendCommunityMessage(VirtualDindiProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    provider.sendCommunityMessage(text);
    _messageController.clear();
  }

  void _showPostAnnouncementDialog(BuildContext context, VirtualDindiProvider provider) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.campaign_rounded, color: WariColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text('Post Official Dindi Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title',
                  hintText: 'e.g. Schedule Update / Palkhi Arrival',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Announcement Message',
                  hintText: 'Type details for all Varkari pilgrims...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WariColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  final msg = messageController.text.trim();
                  if (title.isEmpty || msg.isEmpty) return;

                  provider.sendLeaderBroadcast(
                    title: title,
                    message: msg,
                    type: 'ANNOUNCEMENT',
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement published to all Dindi members in real time.')),
                  );
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Publish Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPalkhiAudioBroadcastDialog(BuildContext context, VirtualDindiProvider provider) {
    final titleController = TextEditingController(text: 'Palkhi Voice Audio Broadcast');
    final captionController = TextEditingController();
    bool isRecordingSimulated = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.mic_rounded, color: WariColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text('Palkhi Audio Broadcast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Broadcast Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: captionController,
                    decoration: const InputDecoration(
                      labelText: 'Optional Audio Caption / Instructions',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simulated Audio Recording Control Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WariColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isRecordingSimulated ? WariColors.danger : WariColors.primary,
                          child: Icon(
                            isRecordingSimulated ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRecordingSimulated ? 'Recording Palkhi Audio... (00:14)' : 'Ready to Record Voice Broadcast',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                isRecordingSimulated ? 'Tap Stop when finished' : 'Tap Record to capture audio instructions',
                                style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRecordingSimulated ? WariColors.danger : WariColors.primary,
                          ),
                          onPressed: () {
                            setModalState(() {
                              isRecordingSimulated = !isRecordingSimulated;
                            });
                          },
                          child: Text(isRecordingSimulated ? 'STOP' : 'REC', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final title = titleController.text.trim();
                      final caption = captionController.text.trim();

                      provider.sendLeaderBroadcast(
                        title: title.isEmpty ? 'Palkhi Voice Audio Broadcast' : title,
                        message: caption.isEmpty ? 'Live audio message from Dindi Leader' : caption,
                        type: 'PALKHI_AUDIO',
                        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Palkhi Audio Broadcast published to all Dindi members.')),
                      );
                    },
                    icon: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
                    label: const Text('Publish Audio Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final activeDindi = dindiProvider.activeDindi;

    if (activeDindi == null && widget.dindiId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dindi Community')),
        body: const Center(
          child: WariEmptyState(
            icon: Icons.groups_outlined,
            title: 'No Active Dindi Communication',
            subtitle: 'Join a Virtual Dindi to participate in official announcements and community chat.',
          ),
        ),
      );
    }

    final isLeaderOrAdmin = userProvider.currentRole == UserRole.DINDI_LEADER || userProvider.currentRole == UserRole.ADMIN;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text(activeDindi != null ? '${activeDindi.name} Channel' : 'Dindi Communication'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WariColors.primary,
          labelColor: WariColors.primaryDark,
          unselectedLabelColor: WariColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: '📢 Announcements'),
            Tab(icon: Icon(Icons.forum_rounded, size: 18), text: '💬 General Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Official Announcements Channel
          _buildAnnouncementsTab(dindiProvider, userProvider, isLeaderOrAdmin),

          // Tab 2: General Chat / Community Messages Tab
          _buildCommunityChatTab(dindiProvider, userProvider),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(VirtualDindiProvider dindiProvider, UserProvider userProvider, bool isLeaderOrAdmin) {
    final broadcasts = dindiProvider.broadcasts;

    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
        // Leader Action Bar (Only visible to Leaders & Admins)
        if (isLeaderOrAdmin) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WariColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
              border: Border.all(color: WariColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: WariColors.primaryDark, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Dindi Leader Controls',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: WariColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WariColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showPostAnnouncementDialog(context, dindiProvider),
                        icon: const Icon(Icons.add_alert_rounded, size: 16, color: Colors.white),
                        label: const Text('Post Text', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WariColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showPalkhiAudioBroadcastDialog(context, dindiProvider),
                        icon: const Icon(Icons.graphic_eq_rounded, size: 16, color: Colors.white),
                        label: const Text('Palkhi Audio', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),
        ] else ...[
          // Varkari Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WariColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
              border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_user_rounded, color: WariColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Official Dindi Broadcast Channel — Real-time verified updates & audio from your Leader.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WariColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),
        ],

        if (broadcasts.isEmpty)
          const WariEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No Official Announcements',
            subtitle: 'New verified updates and Palkhi voice broadcasts from your Leader will appear here.',
          )
        else
          ...broadcasts.map((b) => WariCard(
                margin: const EdgeInsets.only(bottom: 12),
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
                    const SizedBox(height: 8),
                    Text(b.title, style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Leader: ${b.sender} • ${b.message}', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                    if (b.audioUrl != null && b.audioUrl!.isNotEmpty)
                      DindiAudioPlayerWidget(
                        audioUrl: b.audioUrl!,
                        title: b.title,
                      ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildCommunityChatTab(VirtualDindiProvider dindiProvider, UserProvider userProvider) {
    final messages = dindiProvider.communityMessages;
    final currentUid = userProvider.currentUser?.userId ?? '';

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const WariEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No Community Messages',
                  subtitle: 'Start a conversation with your fellow Dindi pilgrims!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(WariSpacing.base),
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.authorId == currentUid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? WariColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                          border: Border.all(color: isMe ? WariColors.primaryDark : WariColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.authorName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white70 : WariColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('hh:mm a').format(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isMe ? Colors.white54 : WariColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: isMe ? Colors.white : WariColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Text Message Input Bar (Both Leaders and Varkaris can send general chat messages)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: WariColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message to your Dindi group...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: (_) => _sendCommunityMessage(dindiProvider),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: WariColors.primary),
                onPressed: () => _sendCommunityMessage(dindiProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
