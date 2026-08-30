// ignore_for_file: constant_identifier_names

/// Virtual Dindi Operational Status Lifecycle.
enum VirtualDindiStatus {
  ACTIVE,
  PAUSED,
  ENDED,
}

extension VirtualDindiStatusX on VirtualDindiStatus {
  String get displayName {
    switch (this) {
      case VirtualDindiStatus.ACTIVE: return 'Active Travel Mode';
      case VirtualDindiStatus.PAUSED: return 'Halt / Rest Mode';
      case VirtualDindiStatus.ENDED:  return 'Journey Completed';
    }
  }

  static VirtualDindiStatus fromString(String str) {
    final upper = str.trim().toUpperCase();
    return VirtualDindiStatus.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => VirtualDindiStatus.ACTIVE,
    );
  }
}

/// Member Separation State Lifecycle.
enum SeparationState {
  SAFE,
  CAUTION,
  SEPARATED,
  CRITICAL,
  RETURNING,
}

extension SeparationStateX on SeparationState {
  String get displayName {
    switch (this) {
      case SeparationState.SAFE:      return 'Within Group Boundary';
      case SeparationState.CAUTION:   return 'Approaching Boundary';
      case SeparationState.SEPARATED: return 'Separated from Dindi';
      case SeparationState.CRITICAL:  return 'CRITICAL Separation Alert';
      case SeparationState.RETURNING: return 'Returning to Dindi Group';
    }
  }

  static SeparationState fromString(String str) {
    final upper = str.trim().toUpperCase();
    return SeparationState.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => SeparationState.SAFE,
    );
  }
}

/// Movement Trend Analysis relative to Group Center.
enum MovementTrend {
  MOVING_AWAY,
  STABLE_SEPARATION,
  RETURNING,
}

extension MovementTrendX on MovementTrend {
  String get displayName {
    switch (this) {
      case MovementTrend.MOVING_AWAY:        return 'Moving Away ↗';
      case MovementTrend.STABLE_SEPARATION:  return 'Stable Distance ➔';
      case MovementTrend.RETURNING:          return 'Returning to Group ↘';
    }
  }

  static MovementTrend fromString(String str) {
    final upper = str.trim().toUpperCase();
    return MovementTrend.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => MovementTrend.STABLE_SEPARATION,
    );
  }
}

/// Event Types for Virtual Dindi Audit and Realtime Feed.
enum VirtualDindiEventType {
  MEMBER_JOINED,
  MEMBER_LEFT,
  DINDI_STARTED,
  DINDI_PAUSED,
  DINDI_ENDED,
  MEMBER_APPROACHING_BOUNDARY,
  MEMBER_SEPARATED,
  MEMBER_CRITICAL_SEPARATION,
  REUNIFICATION_STARTED,
  REUNIFICATION_COMPLETED,
  BROADCAST_SENT,
}

extension VirtualDindiEventTypeX on VirtualDindiEventType {
  static VirtualDindiEventType fromString(String str) {
    final upper = str.trim().toUpperCase();
    return VirtualDindiEventType.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => VirtualDindiEventType.MEMBER_JOINED,
    );
  }
}

/// Core Virtual Dindi Domain Model.
class VirtualDindi {
  final String dindiId;
  final String name;
  final String description;
  final String joinCode;
  final String leaderUid;
  final String leaderName;
  final VirtualDindiStatus status;
  final String createdAt;
  final String updatedAt;
  final double meetingPointLat;
  final double meetingPointLng;
  final String meetingPointName;
  final double safeRadiusMeters;
  final double separationThresholdMeters;
  final double criticalThresholdMeters;
  final int activeMemberCount;

  const VirtualDindi({
    required this.dindiId,
    required this.name,
    this.description = '',
    required this.joinCode,
    required this.leaderUid,
    required this.leaderName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.meetingPointLat,
    required this.meetingPointLng,
    required this.meetingPointName,
    this.safeRadiusMeters = 75.0,
    this.separationThresholdMeters = 150.0,
    this.criticalThresholdMeters = 300.0,
    this.activeMemberCount = 1,
  });

  factory VirtualDindi.fromJson(Map<String, dynamic> json) {
    return VirtualDindi(
      dindiId: json['dindi_id'] as String? ?? json['dindiId'] as String? ?? '',
      name: json['name'] as String? ?? 'Virtual Dindi',
      description: json['description'] as String? ?? '',
      joinCode: json['join_code'] as String? ?? json['joinCode'] as String? ?? 'VDND-0000',
      leaderUid: json['leader_uid'] as String? ?? json['leaderUid'] as String? ?? '',
      leaderName: json['leader_name'] as String? ?? json['leaderName'] as String? ?? 'Dindi Leader',
      status: VirtualDindiStatusX.fromString(json['status'] as String? ?? 'ACTIVE'),
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      meetingPointLat: (json['meeting_point_lat'] as num?)?.toDouble() ?? (json['meetingPointLat'] as num?)?.toDouble() ?? 18.5204,
      meetingPointLng: (json['meeting_point_lng'] as num?)?.toDouble() ?? (json['meetingPointLng'] as num?)?.toDouble() ?? 73.8567,
      meetingPointName: json['meeting_point_name'] as String? ?? json['meetingPointName'] as String? ?? 'Palkhi Main Rest Area',
      safeRadiusMeters: (json['safe_radius_meters'] as num?)?.toDouble() ?? 75.0,
      separationThresholdMeters: (json['separation_threshold_meters'] as num?)?.toDouble() ?? 150.0,
      criticalThresholdMeters: (json['critical_threshold_meters'] as num?)?.toDouble() ?? 300.0,
      activeMemberCount: json['active_member_count'] as int? ?? 1,
    );
  }

  String get qrToken => 'WV_DINDI:$dindiId';

  Map<String, dynamic> toJson() {
    return {
      'dindi_id': dindiId,
      'name': name,
      'description': description,
      'join_code': joinCode,
      'qr_token': qrToken,
      'leader_uid': leaderUid,
      'leader_name': leaderName,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'meeting_point_lat': meetingPointLat,
      'meeting_point_lng': meetingPointLng,
      'meeting_point_name': meetingPointName,
      'safe_radius_meters': safeRadiusMeters,
      'separation_threshold_meters': separationThresholdMeters,
      'critical_threshold_meters': criticalThresholdMeters,
      'active_member_count': activeMemberCount,
    };
  }

  VirtualDindi copyWith({
    VirtualDindiStatus? status,
    double? meetingPointLat,
    double? meetingPointLng,
    String? meetingPointName,
    int? activeMemberCount,
    String? updatedAt,
  }) {
    return VirtualDindi(
      dindiId: dindiId,
      name: name,
      description: description,
      joinCode: joinCode,
      leaderUid: leaderUid,
      leaderName: leaderName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      meetingPointLat: meetingPointLat ?? this.meetingPointLat,
      meetingPointLng: meetingPointLng ?? this.meetingPointLng,
      meetingPointName: meetingPointName ?? this.meetingPointName,
      safeRadiusMeters: safeRadiusMeters,
      separationThresholdMeters: separationThresholdMeters,
      criticalThresholdMeters: criticalThresholdMeters,
      activeMemberCount: activeMemberCount ?? this.activeMemberCount,
    );
  }
}

/// Member Record inside Virtual Dindi (`virtual_dindis/{dindiId}/members/{uid}`).
class VirtualDindiMember {
  final String uid;
  final String displayName;
  final String role;
  final String joinedAt;
  final String memberStatus; // 'ACTIVE', 'PAUSED', 'LEFT'
  final double lastLatitude;
  final double lastLongitude;
  final double accuracyMeters;
  final String lastLocationAt;
  final bool isInsideDindi;
  final double distanceFromGroupMeters;
  final SeparationState separationState;
  final MovementTrend trend;
  final int? batteryLevel;
  final String lastOnlineAt;
  final bool isLeader;
  final String? qrCode;
  final String? qrPayload;

  const VirtualDindiMember({
    required this.uid,
    required this.displayName,
    this.role = 'VARKARI',
    required this.joinedAt,
    this.memberStatus = 'ACTIVE',
    required this.lastLatitude,
    required this.lastLongitude,
    this.accuracyMeters = 10.0,
    required this.lastLocationAt,
    this.isInsideDindi = true,
    this.distanceFromGroupMeters = 0.0,
    this.separationState = SeparationState.SAFE,
    this.trend = MovementTrend.STABLE_SEPARATION,
    this.batteryLevel,
    required this.lastOnlineAt,
    this.isLeader = false,
    this.qrCode,
    this.qrPayload,
  });

  String get formattedQrPayload {
    if (qrPayload != null && qrPayload!.isNotEmpty) return qrPayload!;
    return 'VARKARI\nID: $uid\nNAME: $displayName\nDINDI: Virtual Dindi\nREF: REG-2026-WARI';
  }

  factory VirtualDindiMember.fromJson(Map<String, dynamic> json) {
    return VirtualDindiMember(
      uid: json['uid'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? 'Varkari Member',
      role: json['role'] as String? ?? 'VARKARI',
      joinedAt: json['joined_at'] as String? ?? DateTime.now().toIso8601String(),
      memberStatus: json['member_status'] as String? ?? 'ACTIVE',
      lastLatitude: (json['last_latitude'] as num?)?.toDouble() ?? 18.5204,
      lastLongitude: (json['last_longitude'] as num?)?.toDouble() ?? 73.8567,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble() ?? 10.0,
      lastLocationAt: json['last_location_at'] as String? ?? DateTime.now().toIso8601String(),
      isInsideDindi: json['is_inside_dindi'] as bool? ?? true,
      distanceFromGroupMeters: (json['distance_from_group_meters'] as num?)?.toDouble() ?? 0.0,
      separationState: SeparationStateX.fromString(json['separation_state'] as String? ?? 'SAFE'),
      trend: MovementTrendX.fromString(json['trend'] as String? ?? 'STABLE_SEPARATION'),
      batteryLevel: json['battery_level'] as int?,
      lastOnlineAt: json['last_online_at'] as String? ?? DateTime.now().toIso8601String(),
      isLeader: json['is_leader'] as bool? ?? false,
      qrCode: json['qr_code'] as String? ?? json['qrCode'] as String?,
      qrPayload: json['qr_payload'] as String? ?? json['qrPayload'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'display_name': displayName,
      'role': role,
      'joined_at': joinedAt,
      'member_status': memberStatus,
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'accuracy_meters': accuracyMeters,
      'last_location_at': lastLocationAt,
      'is_inside_dindi': isInsideDindi,
      'distance_from_group_meters': distanceFromGroupMeters,
      'separation_state': separationState.name,
      'trend': trend.name,
      'battery_level': batteryLevel,
      'last_online_at': lastOnlineAt,
      'is_leader': isLeader,
      'qr_code': qrCode,
      'qr_payload': qrPayload,
    };
  }

  VirtualDindiMember copyWith({
    double? lastLatitude,
    double? lastLongitude,
    double? accuracyMeters,
    String? lastLocationAt,
    bool? isInsideDindi,
    double? distanceFromGroupMeters,
    SeparationState? separationState,
    MovementTrend? trend,
    String? lastOnlineAt,
    int? batteryLevel,
  }) {
    return VirtualDindiMember(
      uid: uid,
      displayName: displayName,
      role: role,
      joinedAt: joinedAt,
      memberStatus: memberStatus,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      isInsideDindi: isInsideDindi ?? this.isInsideDindi,
      distanceFromGroupMeters: distanceFromGroupMeters ?? this.distanceFromGroupMeters,
      separationState: separationState ?? this.separationState,
      trend: trend ?? this.trend,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
      isLeader: isLeader,
    );
  }
}

/// Audit Log & Stream Event inside `virtual_dindis/{dindiId}/events/{eventId}`.
class VirtualDindiEvent {
  final String eventId;
  final String dindiId;
  final VirtualDindiEventType type;
  final String actorUid;
  final String targetUid;
  final String details;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String timestamp;
  final bool createdOffline;
  final String? syncedAt;

  const VirtualDindiEvent({
    required this.eventId,
    required this.dindiId,
    required this.type,
    required this.actorUid,
    required this.targetUid,
    required this.details,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    required this.timestamp,
    this.createdOffline = false,
    this.syncedAt,
  });

  factory VirtualDindiEvent.fromJson(Map<String, dynamic> json) {
    return VirtualDindiEvent(
      eventId: json['event_id'] as String? ?? json['id'] as String? ?? '',
      dindiId: json['dindi_id'] as String? ?? '',
      type: VirtualDindiEventTypeX.fromString(json['type'] as String? ?? 'MEMBER_JOINED'),
      actorUid: json['actor_uid'] as String? ?? '',
      targetUid: json['target_uid'] as String? ?? '',
      details: json['details'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      createdOffline: json['created_offline'] as bool? ?? false,
      syncedAt: json['synced_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'dindi_id': dindiId,
      'type': type.name,
      'actor_uid': actorUid,
      'target_uid': targetUid,
      'details': details,
      'latitude': latitude,
      'longitude': longitude,
      'distance_meters': distanceMeters,
      'timestamp': timestamp,
      'created_offline': createdOffline,
      'synced_at': syncedAt,
    };
  }
}
