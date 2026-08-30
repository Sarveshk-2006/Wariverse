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
                  onTap: () => _showSeparationDetailModal(context, m, dindi.name),
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
    final payload = member.formattedQrPayload;
    final varkariId = 'WVRK-${member.uid.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('ID: $varkariId • Dindi: $dindiName', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
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
                data: payload,
                version: QrVersions.auto,
                size: 160.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WariColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                payload,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: WariColors.primaryDark),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Official Verified WariVerse Pilgrim Identity (Google Lens Compatible)',
              style: TextStyle(fontSize: 10, color: WariColors.success, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSeparationDetailModal(BuildContext context, VirtualDindiMember member, String dindiName) {
    final String varkariId = 'WVRK-${member.uid.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}';
    final isSeparated = member.separationState == SeparationState.SEPARATED || member.separationState == SeparationState.CRITICAL;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isSeparated ? WariColors.danger : WariColors.success).withValues(alpha: 0.15),
                  radius: 24,
                  child: Icon(
                    isSeparated ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: isSeparated ? WariColors.danger : WariColors.success,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.displayName, style: WariTypography.titleLarge),
                      Text('ID: $varkariId • Dindi: $dindiName', style: WariTypography.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSeparated ? WariColors.danger : WariColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.separationState.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WariColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('DISTANCE', style: TextStyle(fontSize: 10, color: WariColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        VirtualDindiEngine.formatDistance(member.distanceFromGroupMeters),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WariColors.primaryDark),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('STATUS', style: TextStyle(fontSize: 10, color: WariColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        member.trend.displayName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WariColors.slate800),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('GPS BEACON', style: TextStyle(fontSize: 10, color: WariColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Live 🟢',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WariColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WariPrimaryButton(
              label: 'VIEW LOCATION ON MAP',
              icon: Icons.map_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  '/map',
                  arguments: {
                    'targetLat': member.lastLatitude,
                    'targetLng': member.lastLongitude,
                    'targetName': member.displayName,
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            WariSecondaryButton(
              label: 'SHOW VARKARI PASS QR',
              icon: Icons.qr_code_2_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                _showMemberQrDialog(context, member, dindiName);
              },
            ),
          ],
        ),
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
