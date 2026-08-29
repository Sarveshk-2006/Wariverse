/// Dindi membership status.
enum DindiMembershipStatus {
  active,
  pending,
  inactive,
}

/// Dindi capability flags for centralized permission scoping.
class DindiCapabilities {
  final bool viewSchedule;
  final bool joinDindi;
  final bool viewDigitalPass;
  final bool viewRoute;
  final bool viewCommunity;
  final bool viewAudio;
  final bool viewHealthShield;
  final bool reportCleanliness;

  const DindiCapabilities({
    this.viewSchedule = true,
    this.joinDindi = true,
    this.viewDigitalPass = true,
    this.viewRoute = true,
    this.viewCommunity = true,
    this.viewAudio = true,
    this.viewHealthShield = true,
    this.reportCleanliness = true,
  });
}

/// Core Dindi domain model representing a pilgrimage group unit.
class Dindi {
  final String id;
  final String name;
  final String leaderName;
  final String? leaderPhone;
  final int memberCount;
  final String routeSection;
  final String currentHalt;
  final String nextHalt;
  final String etaNextHalt;
  final bool isActive;
  final String description;

  const Dindi({
    required this.id,
    required this.name,
    required this.leaderName,
    this.leaderPhone,
    required this.memberCount,
    required this.routeSection,
    required this.currentHalt,
    required this.nextHalt,
    required this.etaNextHalt,
    this.isActive = true,
    this.description = '',
  });

  factory Dindi.fromJson(Map<String, dynamic> json) => Dindi(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        leaderName: json['leader_name'] as String? ?? 'Dindi Pramukh',
        leaderPhone: json['leader_phone'] as String?,
        memberCount: json['member_count'] as int? ?? 0,
        routeSection: json['route_section'] as String? ?? 'Alandi-Pandharpur Route',
        currentHalt: json['current_halt'] as String? ?? 'Pune',
        nextHalt: json['next_halt'] as String? ?? 'Saswad',
        etaNextHalt: json['eta_next_halt'] as String? ?? '14:30',
        isActive: json['is_active'] as bool? ?? true,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'leader_name': leaderName,
        'leader_phone': leaderPhone,
        'member_count': memberCount,
        'route_section': routeSection,
        'current_halt': currentHalt,
        'next_halt': nextHalt,
        'eta_next_halt': etaNextHalt,
        'is_active': isActive,
        'description': description,
      };
}

/// Dindi member record.
class DindiMember {
  final String dindiId;
  final String userId;
  final String userName;
  final String userRole;
  final DindiMembershipStatus status;
  final DateTime joinedAt;
  final bool isLeader;

  const DindiMember({
    required this.dindiId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.status,
    required this.joinedAt,
    this.isLeader = false,
  });

  factory DindiMember.fromJson(Map<String, dynamic> json) => DindiMember(
        dindiId: json['dindi_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        userName: json['user_name'] as String? ?? 'Varkari Pilgrim',
        userRole: json['user_role'] as String? ?? 'VARKARI',
        status: DindiMembershipStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'active'),
          orElse: () => DindiMembershipStatus.active,
        ),
        joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
        isLeader: json['is_leader'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'dindi_id': dindiId,
        'user_id': userId,
        'user_name': userName,
        'user_role': userRole,
        'status': status.name,
        'joined_at': joinedAt.toIso8601String(),
        'is_leader': isLeader,
      };
}

/// Digital Dindi Pass model.
class DindiPass {
  final String passId;
  final String dindiId;
  final String dindiName;
  final String userId;
  final String userName;
  final String qrPayload;
  final String status;
  final DateTime issuedAt;

  const DindiPass({
    required this.passId,
    required this.dindiId,
    required this.dindiName,
    required this.userId,
    required this.userName,
    required this.qrPayload,
    this.status = 'ACTIVE',
    required this.issuedAt,
  });

  factory DindiPass.fromJson(Map<String, dynamic> json) => DindiPass(
        passId: json['pass_id'] as String? ?? '',
        dindiId: json['dindi_id'] as String? ?? '',
        dindiName: json['dindi_name'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        userName: json['user_name'] as String? ?? 'Pilgrim',
        qrPayload: json['qr_payload'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        issuedAt: DateTime.tryParse(json['issued_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'pass_id': passId,
        'dindi_id': dindiId,
        'dindi_name': dindiName,
        'user_id': userId,
        'user_name': userName,
        'qr_payload': qrPayload,
        'status': status,
        'issued_at': issuedAt.toIso8601String(),
      };
}
