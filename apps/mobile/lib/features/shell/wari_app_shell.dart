import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/role_navigation_config.dart';

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
    final tabs = RoleNavigationConfig.getTabsForRole(role, tileProvider: widget.tileProvider);
    return tabs.map((tab) {
      return NavigationDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.selectedIcon, color: WariColors.primary),
        label: tab.label,
      );
    }).toList();
  }

  List<Widget> _getPages(UserRole role) {
    final tabs = RoleNavigationConfig.getTabsForRole(role, tileProvider: widget.tileProvider);
    return tabs.map((tab) => tab.pageWidget).toList();
  }

  String _getPageTitle(UserRole role, int index) {
    final tabs = RoleNavigationConfig.getTabsForRole(role, tileProvider: widget.tileProvider);
    final safeIdx = index.clamp(0, tabs.length - 1);
    return tabs[safeIdx].pageTitle;
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/wariverse_logo.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
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
