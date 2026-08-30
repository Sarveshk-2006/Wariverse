import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../core/utils/virtual_dindi_engine.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';

/// "MEMBERS" Tab — Dedicated Live Member Roster & Separation Monitor.
class VirtualDindiMembersScreen extends StatefulWidget {
  const VirtualDindiMembersScreen({super.key});

  @override
  State<VirtualDindiMembersScreen> createState() => _VirtualDindiMembersScreenState();
}

class _VirtualDindiMembersScreenState extends State<VirtualDindiMembersScreen> {
  String _searchQuery = '';
  SeparationState? _filterState;

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final dindi = dindiProvider.activeDindi;

    if (dindi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Member Roster')),
        body: const Center(
          child: WariEmptyState(
            icon: Icons.people_outline,
            title: 'No Active Dindi Roster',
            subtitle: 'Join or create a Dindi to view active member locations.',
          ),
        ),
      );
    }

    final members = dindiProvider.members;
    final currentUid = userProvider.currentUser?.userId ?? '';

    // Filter members by search query and separation state
    final filtered = members.where((m) {
      if (_searchQuery.isNotEmpty && !m.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) && !m.uid.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterState != null && m.separationState != _filterState) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dindi Members (${members.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: WariSpacing.base, vertical: 6),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search member by name or Varkari ID...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL (${members.length})', null),
                      const SizedBox(width: 4),
                      _buildFilterChip('SAFE', SeparationState.SAFE, color: WariColors.success),
                      const SizedBox(width: 4),
                      _buildFilterChip('CAUTION', SeparationState.CAUTION, color: WariColors.warning),
                      const SizedBox(width: 4),
                      _buildFilterChip('SEPARATED', SeparationState.SEPARATED, color: WariColors.crowdOrange),
                      const SizedBox(width: 4),
                      _buildFilterChip('CRITICAL', SeparationState.CRITICAL, color: WariColors.danger),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(WariSpacing.lg),
                child: Text('No members match the selected filter criteria.', style: TextStyle(color: WariColors.textMuted)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(WariSpacing.base),
              itemCount: filtered.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: WariSpacing.xs),
              itemBuilder: (ctx, i) {
                final m = filtered[i];
                final isMe = m.uid == currentUid;

                Color badgeColor;
                switch (m.separationState) {
                  case SeparationState.SAFE: badgeColor = WariColors.success; break;
                  case SeparationState.CAUTION: badgeColor = WariColors.warning; break;
                  case SeparationState.SEPARATED: badgeColor = WariColors.crowdOrange; break;
                  case SeparationState.CRITICAL: badgeColor = WariColors.danger; break;
                  case SeparationState.RETURNING: badgeColor = WariColors.info; break;
                }

                final String varkariId = 'WVRK-${m.uid.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';

                return ListTile(
                  tileColor: WariColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                    side: BorderSide(color: isMe ? WariColors.primary : WariColors.border),
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
                      Expanded(
                        child: Text(
                          m.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.isLeader)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: WariColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: const Text('LEADER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: WariColors.info, borderRadius: BorderRadius.circular(4)),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: $varkariId', style: const TextStyle(fontSize: 10, color: WariColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        '${VirtualDindiEngine.formatDistance(m.distanceFromGroupMeters)} • ${m.trend.displayName} • GPS Live',
                        style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor),
                        ),
                        child: Text(
                          m.separationState.name,
                          style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, size: 22, color: WariColors.primary),
                        onPressed: () => _showMemberQrDialog(context, m, dindi.name),
                        tooltip: 'Member QR Identity Pass',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showMemberQrDialog(BuildContext context, VirtualDindiMember member, String dindiName) {
    final qrToken = 'WVRK:${member.uid}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            Image.asset('assets/images/wariverse_logo.png', width: 44, height: 44),
            const SizedBox(height: 6),
            Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Dindi: $dindiName', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.border),
              ),
              child: QrImageView(
                data: 'https://web-one-tau-17.vercel.app/verify-pilgrim?token=$qrToken',
                version: QrVersions.auto,
                size: 160.0,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              'PASS TOKEN: $qrToken',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: WariColors.primaryDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Official Verified WariVerse Pilgrim Identity',
              style: TextStyle(fontSize: 10, color: WariColors.success, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SeparationState? state, {Color color = WariColors.primary}) {
    final isSelected = _filterState == state;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      onSelected: (_) {
        setState(() {
          _filterState = isSelected ? null : state;
        });
      },
    );
  }
}
