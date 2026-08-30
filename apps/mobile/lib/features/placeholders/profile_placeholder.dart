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
          padding: const EdgeInsets.all(WariSpacing.md),
          decoration: BoxDecoration(
            color: WariColors.surface,
            borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
            border: Border.all(color: WariColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: WariColors.primary,
                    child: Text(
                      user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : 'W',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            WariStatusChip(
                              label: userProvider.currentRole.displayName,
                              color: WariColors.primary,
                              dense: true,
                            ),
                            const SizedBox(width: 6),
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
                    icon: const Icon(LucideIcons.edit3, color: WariColors.primary),
                    onPressed: () => _showEditProfileDialog(context, userProvider),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Active Dindi Information Card
        const SectionHeader(title: 'Joined Dindi Information'),
        WariCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.users, color: WariColors.primary),
                title: Text(
                  activeDindi != null ? activeDindi.name : 'Not Joined to Dindi',
                  style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  activeDindi != null
                      ? 'Code: ${activeDindi.joinCode} • Members: ${activeDindi.activeMemberCount}'
                      : 'Join a Dindi via QR scanner or Dindi code',
                  style: WariTypography.bodySmall,
                ),
                trailing: activeDindi != null
                    ? const WariStatusChip(label: 'ACTIVE', color: WariColors.success, dense: true)
                    : OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.dindiJoin),
                        child: const Text('Join', style: TextStyle(fontSize: 12)),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Role & Capabilities Matrix
        const SectionHeader(title: 'Role & Capabilities Matrix'),
        WariCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.shieldCheck, color: WariColors.primary),
                title: const Text('Active Portal View Role'),
                subtitle: Text(userProvider.currentRole.displayName),
                trailing: DropdownButton<UserRole>(
                  value: userProvider.currentRole,
                  underline: const SizedBox(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      userProvider.setRole(newRole);
                    }
                  },
                  items: UserRole.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.displayName, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(
                  userProvider.isVolunteerEnabled ? LucideIcons.heartHandshake : LucideIcons.heart,
                  color: userProvider.isVolunteerEnabled ? WariColors.success : WariColors.textMuted,
                ),
                title: const Text('Volunteer Willingness'),
                subtitle: const Text('Receive local crowd assistance requests'),
                value: userProvider.isVolunteerEnabled,
                activeTrackColor: WariColors.successLight,
                onChanged: (val) => userProvider.setVolunteerWillingness(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Emergency Safety Contacts Tile
        const SectionHeader(title: 'Emergency Contacts'),
        WariCard(
          child: ListTile(
            leading: const Icon(LucideIcons.phoneCall, color: WariColors.danger),
            title: const Text('Emergency Contacts'),
            subtitle: const Text('Manage family priority emergency contacts'),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // App Preferences & Notification Settings
        const SectionHeader(title: 'App Preferences & Alerts'),
        WariCard(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(LucideIcons.bellRing, color: WariColors.warning),
                title: const Text('Realtime SOS Alerts'),
                subtitle: const Text('Receive instant nearby emergency alerts'),
                value: _sosAlertsEnabled,
                onChanged: _toggleSosAlerts,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(LucideIcons.radio, color: WariColors.primary),
                title: const Text('Palkhi Audio Announcements'),
                subtitle: const Text('Auto-play high priority leader audio broadcasts'),
                value: _audioAlertsEnabled,
                onChanged: _toggleAudioAlerts,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.languages, color: WariColors.primary),
                title: const Text('Language (भाषा)'),
                subtitle: Text(userProvider.currentLanguage == 'mr' ? 'मराठी (Marathi)' : 'English'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('EN', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'mr', label: Text('मराठी', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {userProvider.currentLanguage},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      userProvider.setLanguage(set.first);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),

        // Help, Support & Information
        const SectionHeader(title: 'Support & Information'),
        WariCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.helpCircle, color: WariColors.info),
                title: const Text('Palkhi Help & Helplines'),
                subtitle: const Text('24/7 Emergency & Command Center Numbers'),
                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                onTap: () => _showHelpSupportDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.info, color: WariColors.textMuted),
                title: const Text('WariVerse Version'),
                subtitle: const Text('v2.4.0 • Production Build (Render Backend)'),
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
