import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import 'widgets/dindi_audio_player_widget.dart';

/// Dual-Channel Dindi Communication Center (Official Announcements + Community General Chat).
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
          _buildAnnouncementsTab(dindiProvider, userProvider),

          // Tab 2: General Chat / Community Messages Tab
          _buildCommunityChatTab(dindiProvider, userProvider),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab(VirtualDindiProvider dindiProvider, UserProvider userProvider) {
    final broadcasts = dindiProvider.broadcasts;

    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
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
                  'Official Dindi Broadcast Channel — Only Dindi Leaders and Admins publish updates here.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WariColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

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

        // Text Message Input Bar
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
