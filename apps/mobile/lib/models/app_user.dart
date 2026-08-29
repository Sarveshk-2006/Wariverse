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
    final str = s.toUpperCase();
    if (str == 'SANITATION') return UserRole.CLEANER;
    return UserRole.values.firstWhere(
      (e) => e.name == str,
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
  final bool volunteerEnabled;
  final String volunteerStatus;
  final bool volunteerAvailable;
  final String? dindiCode;
  final bool isDindiLeader;
  final String dindiLeaderStatus;
  final String sanitationStatus;
  final String ngoStatus;

  const AppUser({
    required this.userId,
    required this.role,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.accessToken,
    this.isDemoMode = false,
    this.volunteerEnabled = false,
    this.volunteerStatus = 'NONE',
    this.volunteerAvailable = false,
    this.dindiCode,
    this.isDindiLeader = false,
    this.dindiLeaderStatus = 'NONE',
    this.sanitationStatus = 'NONE',
    this.ngoStatus = 'NONE',
  });

  UserRole get userRole => UserRoleX.fromString(role);

  bool get isVolunteerApproved => volunteerStatus == 'APPROVED' || volunteerEnabled;
  bool get isDindiLeaderApproved => dindiLeaderStatus == 'APPROVED' || isDindiLeader;
  bool get isSanitationApproved => sanitationStatus == 'APPROVED';
  bool get isNgoApproved => ngoStatus == 'APPROVED' || role == 'NGO';

  AppUser copyWith({
    String? userId,
    String? role,
    String? displayName,
    String? email,
    String? photoUrl,
    String? accessToken,
    bool? isDemoMode,
    bool? volunteerEnabled,
    String? volunteerStatus,
    bool? volunteerAvailable,
    String? dindiCode,
    bool? isDindiLeader,
    String? dindiLeaderStatus,
    String? sanitationStatus,
    String? ngoStatus,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      volunteerEnabled: volunteerEnabled ?? this.volunteerEnabled,
      volunteerStatus: volunteerStatus ?? this.volunteerStatus,
      volunteerAvailable: volunteerAvailable ?? this.volunteerAvailable,
      dindiCode: dindiCode ?? this.dindiCode,
      isDindiLeader: isDindiLeader ?? this.isDindiLeader,
      dindiLeaderStatus: dindiLeaderStatus ?? this.dindiLeaderStatus,
      sanitationStatus: sanitationStatus ?? this.sanitationStatus,
      ngoStatus: ngoStatus ?? this.ngoStatus,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['user_id'] as String? ?? json['id'] as String? ?? json['uid'] as String? ?? '',
        role: json['role'] as String? ?? 'VARKARI',
        displayName: json['display_name'] as String? ?? json['full_name'] as String? ?? 'Pilgrim',
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
        accessToken: json['access_token'] as String?,
        isDemoMode: (json['access_token'] as String? ?? '').startsWith('demo-'),
        volunteerEnabled: json['volunteer_enabled'] as bool? ?? false,
        volunteerStatus: json['volunteer_status'] as String? ?? (json['volunteer_enabled'] == true ? 'APPROVED' : 'NONE'),
        volunteerAvailable: json['volunteer_available'] as bool? ?? false,
        dindiCode: json['dindi_code'] as String? ?? json['dindi_id'] as String?,
        isDindiLeader: json['is_dindi_leader'] as bool? ?? false,
        dindiLeaderStatus: json['dindi_leader_status'] as String? ?? (json['is_dindi_leader'] == true ? 'APPROVED' : 'NONE'),
        sanitationStatus: json['sanitation_status'] as String? ?? 'NONE',
        ngoStatus: json['ngo_status'] as String? ?? 'NONE',
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'display_name': displayName,
        'access_token': accessToken,
        'volunteer_enabled': volunteerEnabled,
        'volunteer_status': volunteerStatus,
        'volunteer_available': volunteerAvailable,
        'dindi_code': dindiCode,
        'is_dindi_leader': isDindiLeader,
        'dindi_leader_status': dindiLeaderStatus,
        'sanitation_status': sanitationStatus,
        'ngo_status': ngoStatus,
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
