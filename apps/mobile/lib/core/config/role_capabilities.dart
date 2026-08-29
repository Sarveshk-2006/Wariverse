import '../../models/models_exports.dart';

/// Centralized role capability configuration.
class RoleCapabilities {
  final bool canViewCrowd;
  final bool canViewSos;
  final bool canManageIncidents;
  final bool canManageResources;
  final bool canViewAnalytics;
  final bool canToggleVolunteerStatus;

  const RoleCapabilities({
    required this.canViewCrowd,
    required this.canViewSos,
    required this.canManageIncidents,
    required this.canManageResources,
    required this.canViewAnalytics,
    required this.canToggleVolunteerStatus,
  });

  factory RoleCapabilities.of(UserRole role) {
    switch (role) {
      case UserRole.VARKARI:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: false,
          canManageResources: false,
          canViewAnalytics: false,
          canToggleVolunteerStatus: false,
        );
      case UserRole.DINDI_LEADER:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: false,
          canManageResources: true,
          canViewAnalytics: true,
          canToggleVolunteerStatus: false,
        );

      case UserRole.VOLUNTEER:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: true,
          canManageResources: false,
          canViewAnalytics: false,
          canToggleVolunteerStatus: true,
        );
      case UserRole.POLICE:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: true,
          canManageResources: false,
          canViewAnalytics: true,
          canToggleVolunteerStatus: false,
        );
      case UserRole.MEDICAL_TEAM:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: true,
          canManageResources: true,
          canViewAnalytics: true,
          canToggleVolunteerStatus: false,
        );
      case UserRole.NGO:
      case UserRole.SERVICE_PROVIDER:
      case UserRole.CLEANER:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: false,
          canManageIncidents: false,
          canManageResources: true,
          canViewAnalytics: false,
          canToggleVolunteerStatus: false,
        );
      case UserRole.ADMIN:
        return const RoleCapabilities(
          canViewCrowd: true,
          canViewSos: true,
          canManageIncidents: true,
          canManageResources: true,
          canViewAnalytics: true,
          canToggleVolunteerStatus: false,
        );
    }
  }
}
