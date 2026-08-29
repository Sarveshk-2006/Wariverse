// ignore_for_file: constant_identifier_names

/// User roles matching the backend UserRole enum exactly.
enum UserRole {
  VARKARI,
  DINDI_LEADER,
  VOLUNTEER,
  MEDICAL_TEAM,
  POLICE,
  NGO,
  SERVICE_PROVIDER,
  CLEANER,
  ADMIN,
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.VARKARI:        return 'Varkari Pilgrim';
      case UserRole.DINDI_LEADER:   return 'Dindi Leader / Pramukh';
      case UserRole.VOLUNTEER:      return 'Volunteer';
      case UserRole.MEDICAL_TEAM:   return 'Medical Team';
      case UserRole.POLICE:         return 'Police / Security';
      case UserRole.NGO:            return 'NGO Coordinator';
      case UserRole.SERVICE_PROVIDER: return 'Service Provider';
      case UserRole.CLEANER:        return 'Sanitation Staff';
      case UserRole.ADMIN:          return 'Command Center Admin';
    }
  }

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (e) => e.name == s.toUpperCase(),
      orElse: () => UserRole.VARKARI,
    );
  }
}

/// Lightweight user model returned after login.
class AppUser {
  final String userId;
  final String role;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String? accessToken;
  final bool isDemoMode;

  const AppUser({
    required this.userId,
    required this.role,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.accessToken,
    this.isDemoMode = false,
  });

  UserRole get userRole => UserRoleX.fromString(role);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
        role: json['role'] as String? ?? 'VARKARI',
        displayName: json['display_name'] as String? ?? 'Pilgrim',
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
        accessToken: json['access_token'] as String?,
        isDemoMode: (json['access_token'] as String? ?? '').startsWith('demo-'),
      );



  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'display_name': displayName,
        'access_token': accessToken,
      };
}

/// System-wide user statistics.
class UserStats {
  final int totalUsers;
  final int varkaris;
  final int volunteers;
  final int activePilgrims;

  const UserStats({
    required this.totalUsers,
    required this.varkaris,
    required this.volunteers,
    required this.activePilgrims,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalUsers: json['total_users'] as int? ?? 0,
        varkaris: json['varkaris'] as int? ?? 0,
        volunteers: json['volunteers'] as int? ?? 0,
        activePilgrims: json['active_pilgrims'] as int? ?? 0,
      );
}
