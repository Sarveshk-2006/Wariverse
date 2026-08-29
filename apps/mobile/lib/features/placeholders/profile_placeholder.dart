import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';
import '../sos/emergency_contacts_screen.dart';

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: WariColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(height: WariSpacing.sm),
              Text(user?.displayName ?? 'Pilgrim User', style: WariTypography.headlineSmall),
              Text('Role: ${userProvider.currentRole.displayName}', style: WariTypography.caption),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.lg),
        const SectionHeader(title: 'Account & Security Details'),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined, color: WariColors.primary),
          title: Text('Role Privilege Level', style: WariTypography.titleMedium),
          subtitle: Text(userProvider.currentRole.displayName, style: WariTypography.bodySmall),
        ),
        ListTile(
          leading: const Icon(Icons.security, color: WariColors.primary),
          title: Text('Authoritative Authorization', style: WariTypography.titleMedium),
          subtitle: const Text('Governed by WariVerse Backend Identity Policy', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: WariSpacing.base),
        const SectionHeader(title: 'Secondary Operational Capabilities'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  userProvider.isVolunteerApproved ? Icons.volunteer_activism : Icons.handshake_outlined,
                  color: userProvider.isVolunteerApproved ? WariColors.success : WariColors.textMuted,
                ),
                title: const Text('Volunteer Capability'),
                subtitle: Text('Status: ${userProvider.volunteerStatus}'),
                trailing: userProvider.isVolunteerApproved
                    ? Switch(
                        value: userProvider.isVolunteerEnabled,
                        activeTrackColor: WariColors.successLight,
                        onChanged: (enabled) => userProvider.setVolunteerWillingness(enabled),
                      )
                    : WariSecondaryButtonInline(
                        label: userProvider.volunteerStatus == 'REQUESTED' ? 'Pending Approval' : 'Request',
                        onPressed: userProvider.volunteerStatus == 'NONE'
                            ? () { userProvider.requestCapability('volunteer'); }
                            : null,
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  userProvider.isDindiLeaderApproved ? Icons.groups : Icons.groups_outlined,
                  color: userProvider.isDindiLeaderApproved ? WariColors.primary : WariColors.textMuted,
                ),
                title: const Text('Dindi Leader Capability'),
                subtitle: Text('Status: ${userProvider.dindiLeaderStatus}'),
                trailing: userProvider.isDindiLeaderApproved
                    ? const WariStatusChip(label: 'APPROVED', color: WariColors.success, dense: true)
                    : WariSecondaryButtonInline(
                        label: userProvider.dindiLeaderStatus == 'REQUESTED' ? 'Pending Approval' : 'Request',
                        onPressed: userProvider.dindiLeaderStatus == 'NONE'
                            ? () { userProvider.requestCapability('dindi_leader'); }
                            : null,
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  userProvider.isSanitationApproved ? Icons.cleaning_services : Icons.cleaning_services_outlined,
                  color: userProvider.isSanitationApproved ? WariColors.warning : WariColors.textMuted,
                ),
                title: const Text('Sanitation / Field Worker Capability'),
                subtitle: Text('Status: ${userProvider.sanitationStatus}'),
                trailing: userProvider.isSanitationApproved
                    ? const WariStatusChip(label: 'APPROVED', color: WariColors.success, dense: true)
                    : WariSecondaryButtonInline(
                        label: userProvider.sanitationStatus == 'REQUESTED' ? 'Pending Approval' : 'Request',
                        onPressed: userProvider.sanitationStatus == 'NONE'
                            ? () { userProvider.requestCapability('sanitation'); }
                            : null,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.base),
        const SectionHeader(title: 'Emergency Safety Contacts'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.contact_phone, color: WariColors.danger),
            title: const Text('Manage Family Emergency Contacts'),
            subtitle: const Text('Add up to 5 family contacts (Priority 1-5)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: WariSpacing.xl),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            backgroundColor: WariColors.danger,
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () {
            userProvider.logout();
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          },
        ),
      ],
    );
  }
}
