// ignore_for_file: constant_identifier_names

enum ThreatCategory {
  MEDICAL_EMERGENCY,
  ACCIDENT,
  CROWD_DANGER,
  STAMPEDE_RISK,
  MISSING_PERSON,
  LOST_CHILD,
  HARASSMENT,
  SUSPICIOUS_ACTIVITY,
  FIRE,
  WATER_EMERGENCY,
  SANITATION_PROBLEM,
  FOOD_PROBLEM,
  ROAD_BLOCKAGE,
  WEATHER_HAZARD,
  SECURITY_THREAT,
  DINDI_SEPARATION,
  INFRASTRUCTURE_DAMAGE,
  OTHER;

  String get displayName {
    switch (this) {
      case ThreatCategory.MEDICAL_EMERGENCY:
        return 'Medical Emergency';
      case ThreatCategory.ACCIDENT:
        return 'Accident / Injury';
      case ThreatCategory.CROWD_DANGER:
        return 'Crowd Density Danger';
      case ThreatCategory.STAMPEDE_RISK:
        return 'Stampede Risk';
      case ThreatCategory.MISSING_PERSON:
        return 'Missing Pilgrim';
      case ThreatCategory.LOST_CHILD:
        return 'Lost Child';
      case ThreatCategory.HARASSMENT:
        return 'Harassment / Dispute';
      case ThreatCategory.SUSPICIOUS_ACTIVITY:
        return 'Suspicious Activity';
      case ThreatCategory.FIRE:
        return 'Fire Hazard';
      case ThreatCategory.WATER_EMERGENCY:
        return 'Water Supply Emergency';
      case ThreatCategory.SANITATION_PROBLEM:
        return 'Sanitation Problem';
      case ThreatCategory.FOOD_PROBLEM:
        return 'Food Supply Emergency';
      case ThreatCategory.ROAD_BLOCKAGE:
        return 'Road Blockage';
      case ThreatCategory.WEATHER_HAZARD:
        return 'Severe Weather Hazard';
      case ThreatCategory.SECURITY_THREAT:
        return 'Security Threat';
      case ThreatCategory.DINDI_SEPARATION:
        return 'Dindi Separation';
      case ThreatCategory.INFRASTRUCTURE_DAMAGE:
        return 'Infrastructure Damage';
      case ThreatCategory.OTHER:
        return 'Other Incident';
    }
  }
}

enum IncidentSeverity {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL;

  String get displayName {
    switch (this) {
      case IncidentSeverity.LOW:
        return 'LOW';
      case IncidentSeverity.MEDIUM:
        return 'MEDIUM';
      case IncidentSeverity.HIGH:
        return 'HIGH';
      case IncidentSeverity.CRITICAL:
        return 'CRITICAL';
    }
  }
}

enum IncidentStatus {
  CREATED,
  ASSIGNING,
  ASSIGNED,
  ACCEPTED,
  EN_ROUTE,
  ARRIVED,
  RESOLVED,
  REJECTED,
  CANCELLED,
  EXPIRED,
  REASSIGNING;

  String get displayName {
    switch (this) {
      case IncidentStatus.CREATED:
        return 'Report Created';
      case IncidentStatus.ASSIGNING:
        return 'Finding Responder';
      case IncidentStatus.ASSIGNED:
        return 'Volunteer Assigned';
      case IncidentStatus.ACCEPTED:
        return 'Volunteer Accepted';
      case IncidentStatus.EN_ROUTE:
        return 'Volunteer En Route';
      case IncidentStatus.ARRIVED:
        return 'Volunteer Arrived';
      case IncidentStatus.RESOLVED:
        return 'Issue Resolved';
      case IncidentStatus.REJECTED:
        return 'Rejected by Responder';
      case IncidentStatus.CANCELLED:
        return 'Report Cancelled';
      case IncidentStatus.EXPIRED:
        return 'Assignment Expired';
      case IncidentStatus.REASSIGNING:
        return 'Reassigning Responder';
    }
  }
}

class ThreatIncident {
  final String incidentId;
  final String reporterUid;
  final String reporterName;
  final String reporterRole;
  final String reporterPhone;

  final ThreatCategory category;
  final IncidentSeverity severity;
  final String description;

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String locationTimestamp;

  final List<String> mediaUrls;
  final String mediaType; // PHOTO, VIDEO, NONE

  final IncidentStatus status;
  final double priorityScore;

  final String? assignedVolunteerUid;
  final String? assignedVolunteerName;
  final String? assignedVolunteerPhone;

  final double? volunteerLatitude;
  final double? volunteerLongitude;
  final double? volunteerAccuracyMeters;
  final String? volunteerLocationTimestamp;

  final String createdAt;
  final String updatedAt;
  final String? assignedAt;
  final String? acceptedAt;
  final String? enrouteAt;
  final String? arrivedAt;
  final String? resolvedAt;
  final String? cancelledAt;
  final String? resolutionNotes;
  final bool isOffline;

  const ThreatIncident({
    required this.incidentId,
    required this.reporterUid,
    required this.reporterName,
    required this.reporterRole,
    this.reporterPhone = '',
    required this.category,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 10.0,
    required this.locationTimestamp,
    this.mediaUrls = const [],
    this.mediaType = 'NONE',
    required this.status,
    this.priorityScore = 0.0,
    this.assignedVolunteerUid,
    this.assignedVolunteerName,
    this.assignedVolunteerPhone,
    this.volunteerLatitude,
    this.volunteerLongitude,
    this.volunteerAccuracyMeters,
    this.volunteerLocationTimestamp,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.acceptedAt,
    this.enrouteAt,
    this.arrivedAt,
    this.resolvedAt,
    this.cancelledAt,
    this.resolutionNotes,
    this.isOffline = false,
  });

  bool get isActive =>
      status != IncidentStatus.RESOLVED &&
      status != IncidentStatus.CANCELLED &&
      status != IncidentStatus.EXPIRED;

  Map<String, dynamic> toJson() {
    return {
      'incident_id': incidentId,
      'reporter_uid': reporterUid,
      'reporter_name': reporterName,
      'reporter_role': reporterRole,
      'reporter_phone': reporterPhone,
      'category': category.name,
      'severity': severity.name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'location_timestamp': locationTimestamp,
      'media_urls': mediaUrls,
      'media_type': mediaType,
      'status': status.name,
      'priority_score': priorityScore,
      'assigned_volunteer_uid': assignedVolunteerUid,
      'assigned_volunteer_name': assignedVolunteerName,
      'assigned_volunteer_phone': assignedVolunteerPhone,
      'volunteer_latitude': volunteerLatitude,
      'volunteer_longitude': volunteerLongitude,
      'volunteer_accuracy_meters': volunteerAccuracyMeters,
      'volunteer_location_timestamp': volunteerLocationTimestamp,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'assigned_at': assignedAt,
      'accepted_at': acceptedAt,
      'enroute_at': enrouteAt,
      'arrived_at': arrivedAt,
      'resolved_at': resolvedAt,
      'cancelled_at': cancelledAt,
      'resolution_notes': resolutionNotes,
      'is_offline': isOffline,
    };
  }

  factory ThreatIncident.fromJson(Map<String, dynamic> json) {
    return ThreatIncident(
      incidentId: json['incident_id'] as String? ?? json['id'] as String? ?? '',
      reporterUid: json['reporter_uid'] as String? ?? json['user_id'] as String? ?? '',
      reporterName: json['reporter_name'] as String? ?? 'Varkari Pilgrim',
      reporterRole: json['reporter_role'] as String? ?? 'VARKARI',
      reporterPhone: json['reporter_phone'] as String? ?? '',
      category: ThreatCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ThreatCategory.OTHER,
      ),
      severity: IncidentSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => IncidentSeverity.MEDIUM,
      ),
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble() ?? 10.0,
      locationTimestamp: json['location_timestamp'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      mediaUrls: (json['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mediaType: json['media_type'] as String? ?? 'NONE',
      status: IncidentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => IncidentStatus.CREATED,
      ),
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
      assignedVolunteerUid: json['assigned_volunteer_uid'] as String?,
      assignedVolunteerName: json['assigned_volunteer_name'] as String?,
      assignedVolunteerPhone: json['assigned_volunteer_phone'] as String?,
      volunteerLatitude: (json['volunteer_latitude'] as num?)?.toDouble(),
      volunteerLongitude: (json['volunteer_longitude'] as num?)?.toDouble(),
      volunteerAccuracyMeters: (json['volunteer_accuracy_meters'] as num?)?.toDouble(),
      volunteerLocationTimestamp: json['volunteer_location_timestamp'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      assignedAt: json['assigned_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      enrouteAt: json['enroute_at'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      isOffline: json['is_offline'] as bool? ?? false,
    );
  }
}
