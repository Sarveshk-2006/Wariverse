import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../dashboards/role_dashboard_view.dart';
import '../map/map_screen.dart';
import '../sos/sos_screen.dart';
import '../services/services_screen.dart';
import '../ngo/create_distribution_screen.dart';
import '../placeholders/profile_placeholder.dart';

/// Role & Portal-Specific Application Shell with Custom Operational Navigations.
class WariAppShell extends StatefulWidget {
  const WariAppShell({super.key, this.initialTabIndex = 0, this.tileProvider});

  final int initialTabIndex;
  final TileProvider? tileProvider;

  @override
  State<WariAppShell> createState() => _WariAppShellState();
}

class _WariAppShellState extends State<WariAppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<NavigationDestination> _getNavDestinations(UserRole role) {
    switch (role) {
      case UserRole.NGO:
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: WariColors.primary),
            label: 'NGO Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: WariColors.primary),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism, color: WariColors.primary),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active, color: WariColors.danger),
            label: 'Emergency',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: WariColors.primary),
            label: 'Profile',
          ),
        ];

      case UserRole.ADMIN:
        return const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings, color: WariColors.primary),
            label: 'Command Center',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: WariColors.primary),
            label: 'Operations Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning, color: WariColors.danger),
            label: 'SOS & Risk',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: WariColors.primary),
            label: 'Resource Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts, color: WariColors.primary),
            label: 'System Control',
          ),
        ];

      case UserRole.VARKARI:
      default:
        return const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: WariColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: WariColors.primary),
            label: 'Wari Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active, color: WariColors.danger),
            label: 'Alerts & SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: WariColors.primary),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: WariColors.primary),
            label: 'Profile',
          ),
        ];
    }
  }

  List<Widget> _getPages(UserRole role) {
    switch (role) {
      case UserRole.NGO:
        return [
          const RoleDashboardView(),
          MapScreen(tileProvider: widget.tileProvider),
          const CreateDistributionScreen(),
          const SosScreen(),
          const ProfilePlaceholder(),
        ];
      case UserRole.ADMIN:
        return [
          const RoleDashboardView(),
          MapScreen(tileProvider: widget.tileProvider),
          const SosScreen(),
          const CreateDistributionScreen(),
          const ProfilePlaceholder(),
        ];
      case UserRole.VARKARI:
      default:
        return [
          const RoleDashboardView(),
          MapScreen(tileProvider: widget.tileProvider),
          const SosScreen(),
          const ServicesScreen(),
          const ProfilePlaceholder(),
        ];
    }
  }

  String _getPageTitle(UserRole role, int index) {
    switch (role) {
      case UserRole.NGO:
        const titles = ['NGO Operations Hub', 'Resource Deployments Map', 'Publish Aid Resources', 'NGO Emergency & Safety', 'NGO Profile'];
        return titles[index.clamp(0, titles.length - 1)];
      case UserRole.ADMIN:
        const titles = ['Command Center Operations', 'Wari Live Operations Map', 'SOS & Risk Monitoring', 'NGO Resource Oversight', 'Admin System Control'];
        return titles[index.clamp(0, titles.length - 1)];
      case UserRole.VARKARI:
      default:
        const titles = ['WariVerse AI', 'Live Pilgrimage Map', 'Safety & SOS Emergency', 'Pilgrim Services & Facilities', 'Profile & Settings'];
        return titles[index.clamp(0, titles.length - 1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final activeRole = userProvider.currentRole;
    final pages = _getPages(activeRole);
    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return PopScope(
      canPop: safeIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && safeIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _getPageTitle(activeRole, safeIndex),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (userProvider.isDemoMode) ...[
                const SizedBox(width: WariSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: Text(
                    'DEMO',
                    style: WariTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Builder(
              builder: (innerContext) => GestureDetector(
                onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                child: Container(
                  margin: const EdgeInsets.only(right: WariSpacing.base),
                  padding: const EdgeInsets.symmetric(
                    horizontal: WariSpacing.sm,
                    vertical: WariSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(activeRole),
                        size: 14,
                        color: WariColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activeRole.displayName.split(' ').first,
                        style: WariTypography.labelSmall.copyWith(
                          color: WariColors.primaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(WariSpacing.base),
                  color: WariColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: WariColors.primary),
                      ),
                      const SizedBox(height: WariSpacing.sm),
                      Text(
                        userProvider.currentUser?.displayName ?? 'Pilgrim User',
                        style: WariTypography.titleMedium.copyWith(color: Colors.white),
                      ),
                      Text(
                        'Active Role: ${activeRole.displayName}',
                        style: WariTypography.caption.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline, color: WariColors.primary),
                  title: Text('My Profile', style: WariTypography.titleSmall),
                  subtitle: Text(userProvider.currentUser?.email ?? userProvider.currentUser?.userId ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: WariColors.primary),
                  title: Text('Role Authorization', style: WariTypography.titleSmall),
                  subtitle: Text(activeRole.displayName),
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: WariColors.danger),
                  title: Text('Sign Out', style: WariTypography.titleSmall.copyWith(color: WariColors.danger)),
                  onTap: () {
                    Navigator.pop(context);
                    userProvider.logout();
                  },
                ),
                const SizedBox(height: WariSpacing.base),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: safeIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: _onTabTapped,
          destinations: _getNavDestinations(activeRole),
        ),
      ),
    );
  }

  static IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.VARKARI: return Icons.temple_hindu;
      case UserRole.DINDI_LEADER: return Icons.groups;
      case UserRole.VOLUNTEER: return Icons.handshake;
      case UserRole.MEDICAL_TEAM: return Icons.local_hospital;
      case UserRole.POLICE: return Icons.local_police;
      case UserRole.NGO: return Icons.volunteer_activism;
      case UserRole.SERVICE_PROVIDER: return Icons.restaurant;
      case UserRole.CLEANER: return Icons.cleaning_services;
      case UserRole.ADMIN: return Icons.admin_panel_settings;
    }
  }
}
