// ignore_for_file: constant_identifier_names

enum SOSCategory {
  MEDICAL, ACCIDENT, LOST, WOMEN_SAFETY, CHILD, DEHYDRATION, FATIGUE, OTHER
}

enum SOSStatus {
  CREATED, ACKNOWLEDGED, VOLUNTEER_ASSIGNED, MEDICAL_ASSIGNED,
  IN_PROGRESS, RESOLVED, CANCELLED
}

extension SOSCategoryX on SOSCategory {
  String get displayName {
    switch (this) {
      case SOSCategory.MEDICAL:       return 'Medical Emergency';
      case SOSCategory.ACCIDENT:      return 'Accident';
      case SOSCategory.LOST:          return 'Lost Pilgrim';
      case SOSCategory.WOMEN_SAFETY:  return 'Women Safety';
      case SOSCategory.CHILD:         return 'Lost Child';
      case SOSCategory.DEHYDRATION:   return 'Dehydration';
      case SOSCategory.FATIGUE:       return 'Fatigue';
      case SOSCategory.OTHER:         return 'Other Emergency';
    }
  }

  static SOSCategory fromString(String s) => SOSCategory.values.firstWhere(
        (e) => e.name == s.toUpperCase(),
        orElse: () => SOSCategory.OTHER,
      );
}

extension SOSStatusX on SOSStatus {
  String get displayName {
    switch (this) {
      case SOSStatus.CREATED:            return 'Created';
      case SOSStatus.ACKNOWLEDGED:       return 'Acknowledged';
      case SOSStatus.VOLUNTEER_ASSIGNED: return 'Volunteer Assigned';
      case SOSStatus.MEDICAL_ASSIGNED:   return 'Medical Assigned';
      case SOSStatus.IN_PROGRESS:        return 'In Progress';
      case SOSStatus.RESOLVED:           return 'Resolved';
      case SOSStatus.CANCELLED:          return 'Cancelled';
    }
  }

  bool get isActive =>
      this != SOSStatus.RESOLVED && this != SOSStatus.CANCELLED;

  static SOSStatus fromString(String s) => SOSStatus.values.firstWhere(
        (e) => e.name == s.toUpperCase(),
        orElse: () => SOSStatus.CREATED,
      );
}

class SOSIncident {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final SOSCategory category;
  final SOSStatus status;
  final String? description;
  final String? bloodGroup;
  final String? emergencyContact;
  final bool isOffline;
  final String? responderName;
  final double? responderDistanceM;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const SOSIncident({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.status,
    this.description,
    this.bloodGroup,
    this.emergencyContact,
    this.isOffline = false,
    this.responderName,
    this.responderDistanceM,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SOSIncident.fromJson(Map<String, dynamic> json) => SOSIncident(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        category: SOSCategoryX.fromString(json['category'] as String? ?? 'OTHER'),
        status: SOSStatusX.fromString(json['status'] as String? ?? 'CREATED'),
        description: json['description'] as String?,
        bloodGroup: json['blood_group'] as String?,
        emergencyContact: json['emergency_contact'] as String?,
        isOffline: json['is_offline'] as bool? ?? false,
        responderName: json['responder_name'] as String?,
        responderDistanceM: (json['responder_distance_m'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.tryParse(json['resolved_at'] as String)
            : null,
      );

  factory SOSIncident.fromSnapshot(dynamic doc) {
    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    data['id'] = doc.id;
    return SOSIncident.fromJson(data);
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'category': category.name,
        'description': description,
        'blood_group': bloodGroup,
        'emergency_contact': emergencyContact,
        'is_offline': isOffline,
      };
}
