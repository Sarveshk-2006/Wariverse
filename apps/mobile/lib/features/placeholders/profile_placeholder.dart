import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../navigation/app_routes.dart';
import '../sos/emergency_contacts_screen.dart';

/// Authoritative, Production-Ready Profile & Settings Hub.
class ProfilePlaceholder extends StatefulWidget {
  const ProfilePlaceholder({super.key});

  @override
  State<ProfilePlaceholder> createState() => _ProfilePlaceholderState();
}

class _ProfilePlaceholderState extends State<ProfilePlaceholder> {
  bool _sosAlertsEnabled = true;
  bool _audioAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _sosAlertsEnabled = prefs.getBool('pref_sos_alerts') ?? true;
          _audioAlertsEnabled = prefs.getBool('pref_audio_alerts') ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleSosAlerts(bool val) async {
    setState(() => _sosAlertsEnabled = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_sos_alerts', val);
    } catch (_) {}
  }

  Future<void> _toggleAudioAlerts(bool val) async {
    setState(() => _audioAlertsEnabled = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_audio_alerts', val);
    } catch (_) {}
  }

  void _showEditProfileDialog(BuildContext context, UserProvider userProvider) {
    final nameController = TextEditingController(text: userProvider.currentUser?.displayName ?? '');
    final phoneController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: const [
            Icon(LucideIcons.userCheck, color: WariColors.primary),
            SizedBox(width: 8),
            Text('Edit Profile (प्रोफाइल संपादीत करा)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name (पूर्ण नाव)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (फोन नंबर)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              if (newName.isNotEmpty) {
                userProvider.updateProfileInfo(displayName: newName, phone: newPhone);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Profile updated successfully!'),
                    backgroundColor: WariColors.success,
                  ),
                );
              }
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: const [
            Icon(LucideIcons.helpCircle, color: WariColors.primary),
            SizedBox(width: 8),
            Text('Palkhi Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official Palkhi 24/7 Helplines:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.phoneCall, color: WariColors.danger),
              title: const Text('112 — National Emergency'),
              subtitle: const Text('Police, Fire & Disaster Assistance'),
              onTap: () => launchUrl(Uri.parse('tel:112')),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.activity, color: WariColors.success),
              title: const Text('108 — Medical Ambulance'),
              subtitle: const Text('Free Emergency Medical Service'),
              onTap: () => launchUrl(Uri.parse('tel:108')),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.headphones, color: WariColors.primary),
              title: const Text('020-26123456 — Palkhi Command Center'),
              subtitle: const Text('Wari Route Control & Lost Child Desk'),
              onTap: () => launchUrl(Uri.parse('tel:02026123456')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final user = userProvider.currentUser;
    final activeDindi = dindiProvider.activeDindi;

    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
        // Header Profile Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WariColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: WariColors.primary,
                child: Text(
                  user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'W',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Pilgrim Varkari',
                      style: WariTypography.headlineSmall.copyWith(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        WariStatusChip(
                          label: userProvider.currentRole.displayName,
                          color: WariColors.primary,
                          dense: true,
                        ),
                        Text(
                          user?.formattedVarkariId ?? 'WVRK-2026-9041',
                          style: const TextStyle(fontSize: 11, color: WariColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.edit3, color: WariColors.primary, size: 20),
                onPressed: () => _showEditProfileDialog(context, userProvider),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Active Dindi Information Card
        const SectionHeader(title: 'Joined Dindi Information'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WariColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WariColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.users, color: WariColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeDindi != null ? activeDindi.name : 'Not Joined to Dindi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeDindi != null
                          ? 'Code: ${activeDindi.joinCode} • Members: ${activeDindi.activeMemberCount}'
                          : 'Join a Dindi via QR scanner or Dindi code',
                      style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              activeDindi != null
                  ? const WariStatusChip(label: 'ACTIVE', color: WariColors.success, dense: true)
                  : ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.dindiJoin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WariColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(LucideIcons.qrCode, size: 14, color: Colors.white),
                      label: const Text('Join', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Role & Capabilities Matrix
        const SectionHeader(title: 'Role & Capabilities Matrix'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WariColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: WariColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Portal View Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(userProvider.currentRole.displayName, style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                  DropdownButton<UserRole>(
                    value: userProvider.currentRole,
                    underline: const SizedBox(),
                    onChanged: (newRole) {
                      if (newRole != null) userProvider.setRole(newRole);
                    },
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.displayName, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    userProvider.isVolunteerEnabled ? LucideIcons.heartHandshake : LucideIcons.heart,
                    color: userProvider.isVolunteerEnabled ? WariColors.success : WariColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Volunteer Willingness', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Receive local crowd assistance requests', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: userProvider.isVolunteerEnabled,
                    activeTrackColor: WariColors.successLight,
                    onChanged: (val) => userProvider.setVolunteerWillingness(val),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Emergency Safety Contacts Tile
        const SectionHeader(title: 'Emergency Contacts'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WariColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WariColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.phoneCall, color: WariColors.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Emergency Safety Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Manage priority family emergency contacts', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: WariColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // App Preferences & Notification Settings
        const SectionHeader(title: 'App Preferences & Alerts'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WariColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.bellRing, color: WariColors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Realtime SOS Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Receive instant nearby emergency alerts', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sosAlertsEnabled,
                    onChanged: _toggleSosAlerts,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(LucideIcons.radio, color: WariColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Palkhi Audio Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Auto-play leader audio broadcasts', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _audioAlertsEnabled,
                    onChanged: _toggleAudioAlerts,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(LucideIcons.languages, color: WariColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Language (भाषा)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(userProvider.currentLanguage == 'mr' ? 'मराठी (Marathi)' : 'English', style: const TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('EN', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'mr', label: Text('मराठी', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {userProvider.currentLanguage},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) userProvider.setLanguage(set.first);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Support & Information
        const SectionHeader(title: 'Support & Information'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WariColors.border),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => _showHelpSupportDialog(context),
                child: Row(
                  children: [
                    const Icon(LucideIcons.helpCircle, color: WariColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Palkhi Help & Helplines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('24/7 Emergency & Command Center Numbers', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: WariColors.textMuted),
                  ],
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(LucideIcons.info, color: WariColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('WariVerse Version', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('v2.4.0 • Production Build (Render Backend)', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.xl),

        // Sign Out Button
        ElevatedButton.icon(
          icon: const Icon(LucideIcons.logOut, color: Colors.white),
          label: const Text('Sign Out (लॉग आउट करा)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: WariColors.danger,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            userProvider.logout();
            dindiProvider.leaveVirtualDindi();
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          },
        ),
        const SizedBox(height: WariSpacing.xl),
      ],
    );
  }
}
