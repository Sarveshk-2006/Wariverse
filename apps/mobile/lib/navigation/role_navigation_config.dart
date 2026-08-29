import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/models_exports.dart';
import '../features/dashboards/role_dashboard_view.dart';
import '../features/map/map_screen.dart';
import '../features/sos/sos_screen.dart';
import '../features/services/services_screen.dart';
import '../features/ngo/create_distribution_screen.dart';
import '../features/placeholders/profile_placeholder.dart';
import '../features/dindi/virtual_dindi_detail_screen.dart';
import '../features/incidents/volunteer_response_queue_screen.dart';
import '../features/cleanwari/cleanwari_cleaner_screen.dart';

class RoleTabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget pageWidget;
  final String pageTitle;

  const RoleTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.pageWidget,
    required this.pageTitle,
  });
}

/// Centralized role-aware navigation configuration for WariVerse AI multi-portal shell.
class RoleNavigationConfig {
  static List<RoleTabItem> getTabsForRole(UserRole role, {TileProvider? tileProvider}) {
    final liveMapWidget = MapScreen(tileProvider: tileProvider);

    switch (role) {
      // 1. VARKARI PORTAL
      case UserRole.VARKARI:
        return [
          RoleTabItem(
            label: 'HOME',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            pageWidget: const RoleDashboardView(),
            pageTitle: 'WariVerse AI Pilgrim Home',
          ),
          RoleTabItem(
            label: 'LIVE MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'Live Pilgrimage Route Map',
          ),
          RoleTabItem(
            label: 'SAFETY',
            icon: Icons.shield_outlined,
            selectedIcon: Icons.shield,
            pageWidget: const SosScreen(),
            pageTitle: 'Safety, SOS & Threat Reporting',
          ),
          RoleTabItem(
            label: 'SERVICES',
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            pageWidget: const ServicesScreen(),
            pageTitle: 'Pilgrim Services & Facilities',
          ),
          RoleTabItem(
            label: 'PROFILE',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'Pilgrim e-ID & Profile',
          ),
        ];

      // 2. DINDI LEADER PORTAL
      case UserRole.DINDI_LEADER:
        return [
          RoleTabItem(
            label: 'COMMAND',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            pageWidget: const RoleDashboardView(),
            pageTitle: 'Dindi Operations Command',
          ),
          RoleTabItem(
            label: 'MY DINDI',
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
            pageWidget: const VirtualDindiDetailScreen(),
            pageTitle: 'Virtual Dindi Management & Roster',
          ),
          RoleTabItem(
            label: 'LIVE MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'Dindi Route & Member Locations',
          ),
          RoleTabItem(
            label: 'MEMBERS',
            icon: Icons.people_alt_outlined,
            selectedIcon: Icons.people_alt,
            pageWidget: const VirtualDindiDetailScreen(),
            pageTitle: 'Live Member Locations & Separation',
          ),
          RoleTabItem(
            label: 'PROFILE',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'Dindi Leader Profile',
          ),
        ];

      // 3. VOLUNTEER PORTAL
      case UserRole.VOLUNTEER:
        return [
          RoleTabItem(
            label: 'RESPONSE QUEUE',
            icon: Icons.support_agent_outlined,
            selectedIcon: Icons.support_agent,
            pageWidget: const VolunteerResponseQueueScreen(),
            pageTitle: 'Volunteer Live Emergency Queue',
          ),
          RoleTabItem(
            label: 'LIVE MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'Field Responder Live Map',
          ),
          RoleTabItem(
            label: 'ACTIVE TASK',
            icon: Icons.task_alt_outlined,
            selectedIcon: Icons.task_alt,
            pageWidget: const VolunteerResponseQueueScreen(),
            pageTitle: 'Active Incident Response & Navigation',
          ),
          RoleTabItem(
            label: 'HISTORY',
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            pageWidget: const SosScreen(),
            pageTitle: 'Volunteer Incident History',
          ),
          RoleTabItem(
            label: 'PROFILE',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'Volunteer Responder Profile',
          ),
        ];

      // 4. NGO PORTAL
      case UserRole.NGO:
      case UserRole.SERVICE_PROVIDER:
        return [
          RoleTabItem(
            label: 'OPERATIONS',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            pageWidget: const RoleDashboardView(),
            pageTitle: 'NGO Operations Hub',
          ),
          RoleTabItem(
            label: 'DEPLOY AID',
            icon: Icons.add_location_alt_outlined,
            selectedIcon: Icons.add_location_alt,
            pageWidget: const CreateDistributionScreen(),
            pageTitle: 'Publish Live Aid Resource Deployment',
          ),
          RoleTabItem(
            label: 'LIVE MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'NGO Resource Deployments Map',
          ),
          RoleTabItem(
            label: 'DEPLOYMENTS',
            icon: Icons.volunteer_activism_outlined,
            selectedIcon: Icons.volunteer_activism,
            pageWidget: const CreateDistributionScreen(),
            pageTitle: 'Active Aid Distributions List',
          ),
          RoleTabItem(
            label: 'PROFILE',
            icon: Icons.business_outlined,
            selectedIcon: Icons.business,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'NGO Coordinator Profile',
          ),
        ];

      // 5. SANITATION / FIELD WORKER PORTAL
      case UserRole.CLEANER:
        return [
          RoleTabItem(
            label: 'TASKS',
            icon: Icons.cleaning_services_outlined,
            selectedIcon: Icons.cleaning_services,
            pageWidget: const CleanWariCleanerScreen(),
            pageTitle: 'CleanWari Sanitation Dispatch Tasks',
          ),
          RoleTabItem(
            label: 'LIVE MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'Sanitation Facilities & Worker Location',
          ),
          RoleTabItem(
            label: 'ACTIVE TASK',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            pageWidget: const CleanWariCleanerScreen(),
            pageTitle: 'Active Sanitation Cleaning Work',
          ),
          RoleTabItem(
            label: 'HISTORY',
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            pageWidget: const SosScreen(),
            pageTitle: 'Completed Sanitation Logs',
          ),
          RoleTabItem(
            label: 'PROFILE',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'Sanitation Staff Profile',
          ),
        ];

      // 6. ADMIN PORTAL
      case UserRole.ADMIN:
      case UserRole.POLICE:
      case UserRole.MEDICAL_TEAM:
        return [
          RoleTabItem(
            label: 'COMMAND',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings,
            pageWidget: const RoleDashboardView(),
            pageTitle: 'Executive Command Center',
          ),
          RoleTabItem(
            label: 'OPERATIONS MAP',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            pageWidget: liveMapWidget,
            pageTitle: 'Global Pilgrimage Operations Map',
          ),
          RoleTabItem(
            label: 'INCIDENTS',
            icon: Icons.warning_amber_outlined,
            selectedIcon: Icons.warning,
            pageWidget: const SosScreen(),
            pageTitle: 'Realtime Incident Command Stream',
          ),
          RoleTabItem(
            label: 'RESOURCES',
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            pageWidget: const CreateDistributionScreen(),
            pageTitle: 'Global NGO & Service Resource Monitor',
          ),
          RoleTabItem(
            label: 'SYSTEM',
            icon: Icons.manage_accounts_outlined,
            selectedIcon: Icons.manage_accounts,
            pageWidget: const ProfilePlaceholder(),
            pageTitle: 'System Approvals & Audit Control',
          ),
        ];
    }
  }
}
