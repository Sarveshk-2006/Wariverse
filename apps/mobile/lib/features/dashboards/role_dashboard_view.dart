import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env_config.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';
import 'dindi_leader_dashboard.dart';
import 'volunteer_dashboard.dart';
import '../cleanwari/cleanwari_cleaner_screen.dart';
import '../sos/sos_incident_history_screen.dart';
import '../ngo/ngo_dashboard.dart';

/// Centralized role-based operational dashboard renderer for WariVerse Field Mobile.
class RoleDashboardView extends StatelessWidget {
  const RoleDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final activeRole = userProvider.currentRole;

    switch (activeRole) {
      case UserRole.VARKARI:
        if (userProvider.isVolunteerEnabled) {
          return const VolunteerDashboard();
        }
        return const HomeScreen();
      case UserRole.DINDI_LEADER:
        return const DindiLeaderDashboard();
      case UserRole.VOLUNTEER:
      case UserRole.POLICE:
      case UserRole.MEDICAL_TEAM:
        return const VolunteerDashboard();
      case UserRole.CLEANER:
        return const CleanWariCleanerScreen();
      case UserRole.NGO:
        return const NgoDashboard();
      case UserRole.ADMIN:
      case UserRole.SERVICE_PROVIDER:
        return const WebPortalRedirectWidget();
    }
  }
}

/// Screen presented when an Admin or NGO account logs into the Field Mobile App.
class WebPortalRedirectWidget extends StatelessWidget {
  const WebPortalRedirectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.currentRole;
    final isAdmin = role == UserRole.ADMIN;
    final isNgo = role == UserRole.NGO || role == UserRole.SERVICE_PROVIDER;

    final String titleText = isAdmin
        ? 'Executive Command Center'
        : (isNgo ? 'NGO Operations Portal' : 'Operations Web Portal');

    final String buttonLabel = isAdmin
        ? 'Open Admin Web Dashboard →'
        : (isNgo ? 'Open NGO Web Dashboard →' : 'Open Web Dashboard →');

    final String targetUrl = isAdmin
        ? EnvConfig.adminDashboardUrl
        : (isNgo ? EnvConfig.ngoDashboardUrl : EnvConfig.webBaseUrl);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(WariSpacing.lg),
            decoration: BoxDecoration(
              color: WariColors.surface,
              borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
              border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.laptop_mac_rounded, size: 36, color: WariColors.primaryDark),
                ),
                const SizedBox(height: WariSpacing.base),
                Text(
                  titleText,
                  style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'Operational controls are available in the WariVerse Web Dashboard.',
                  style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WariSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(targetUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WariSpacing.radiusMd)),
                    ),
                  ),
                ),
                const SizedBox(height: WariSpacing.base),
                const Divider(),
                const SizedBox(height: WariSpacing.sm),
                Text(
                  'Emergency & SOS History',
                  style: WariTypography.titleSmall,
                ),
                const SizedBox(height: WariSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SosIncidentHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, color: WariColors.primary),
                    label: const Text('View Incident History', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: WariColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WariSpacing.radiusMd)),
                    ),
                  ),
                ),
                const SizedBox(height: WariSpacing.sm),
                TextButton(
                  onPressed: () => userProvider.switchRole(UserRole.VARKARI),
                  child: const Text('Switch to Varkari Field View'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

