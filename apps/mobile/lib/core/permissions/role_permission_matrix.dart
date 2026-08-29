import '../../models/app_user.dart';

/// Centralized capability and permission matrix for WariVerse AI roles.
class RolePermissionMatrix {
  static bool canAccessAdmin(UserRole role) => role == UserRole.ADMIN;
  static bool canAccessDindiLeader(UserRole role) => role == UserRole.DINDI_LEADER || role == UserRole.ADMIN;
  static bool canAccessMedical(UserRole role) => role == UserRole.MEDICAL_TEAM || role == UserRole.ADMIN;
  static bool canAccessPolice(UserRole role) => role == UserRole.POLICE || role == UserRole.ADMIN;
  static bool canAccessVolunteer(UserRole role) => role == UserRole.VOLUNTEER || role == UserRole.ADMIN;
  static bool canAccessNgo(UserRole role) => role == UserRole.NGO || role == UserRole.ADMIN;
  static bool canAccessCleaner(UserRole role) => role == UserRole.CLEANER || role == UserRole.ADMIN;
  static bool canAccessServiceProvider(UserRole role) => role == UserRole.SERVICE_PROVIDER || role == UserRole.ADMIN;

  /// Returns allowed bottom navigation items for current role.
  static List<String> getAllowedNavigationTabs(UserRole role) {
    switch (role) {
      case UserRole.VARKARI:
        return ['Home', 'Map', 'SOS', 'Services', 'Profile'];
      case UserRole.DINDI_LEADER:
        return ['Dindi Management', 'Members', 'Live Beacon', 'SOS', 'Profile'];
      case UserRole.VOLUNTEER:
        return ['Operations', 'Tasks', 'Map', 'SOS', 'Profile'];
      case UserRole.MEDICAL_TEAM:
        return ['Triage', 'Camps', 'Map', 'SOS', 'Profile'];
      case UserRole.POLICE:
        return ['Security', 'Red Zones', 'Map', 'SOS', 'Profile'];
      case UserRole.NGO:
        return ['Relief', 'Logistics', 'Map', 'SOS', 'Profile'];
      case UserRole.ADMIN:
        return ['Command Center', 'Analytics', 'Map', 'SOS', 'Profile'];
      default:
        return ['Home', 'Map', 'SOS', 'Services', 'Profile'];
    }
  }

}
