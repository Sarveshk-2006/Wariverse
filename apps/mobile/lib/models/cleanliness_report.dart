// ignore_for_file: constant_identifier_names

/// Category of cleanliness issues reported at toilet facilities.
enum CleanlinessIssueType {
  NO_WATER,
  NEEDS_CLEANING,
  OVERFLOW,
  DAMAGED,
  OTHER,
}

extension CleanlinessIssueTypeX on CleanlinessIssueType {
  String get displayName {
    switch (this) {
      case CleanlinessIssueType.NO_WATER:       return 'No Water (पाणी नाही)';
      case CleanlinessIssueType.NEEDS_CLEANING: return 'Needs Cleaning (स्वच्छता आवश्यक)';
      case CleanlinessIssueType.OVERFLOW:       return 'Overflow (पाणी साचले आहे)';
      case CleanlinessIssueType.DAMAGED:        return 'Damaged (नुकसान झाले आहे)';
      case CleanlinessIssueType.OTHER:          return 'Other Issue (इतर समस्या)';
    }
  }
}

/// Status lifecycle of a CleanWari cleanliness report.
enum CleanlinessReportStatus {
  REPORTED,
  ASSIGNED,
  ACCEPTED,
  IN_PROGRESS,
  RESOLVED,
  UNABLE_TO_COMPLETE,
}

extension CleanlinessReportStatusX on CleanlinessReportStatus {
  String get displayName {
    switch (this) {
      case CleanlinessReportStatus.REPORTED:           return 'REPORTED (नोंदणी झाली)';
      case CleanlinessReportStatus.ASSIGNED:           return 'ASSIGNED (कर्मचारी नियुक्त)';
      case CleanlinessReportStatus.ACCEPTED:           return 'ACCEPTED (स्वीकारले)';
      case CleanlinessReportStatus.IN_PROGRESS:        return 'IN PROGRESS (काम सुरू)';
      case CleanlinessReportStatus.RESOLVED:           return 'RESOLVED (निराकरण झाले)';
      case CleanlinessReportStatus.UNABLE_TO_COMPLETE: return 'UNABLE TO COMPLETE (अपूर्ण)';
    }
  }
}

/// Priority tier of dispatch task.
enum CleanlinessReportPriority {
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL,
}

/// CleanWari cleanliness report and cleaner dispatch task model.
class CleanlinessReport {
  final String id;
  final String toiletId;
  final String toiletQrCode;
  final String toiletName;
  final String reporterId;
  final CleanlinessIssueType issueType;
  final String description;
  final DateTime reportedAt;
  final CleanlinessReportStatus status;
  final CleanlinessReportPriority priority;
  final String? assignedCleanerId;
  final String? assignedCleanerName;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String reporterRole;
  final double? latitude;
  final double? longitude;
  final bool isDemo;

  const CleanlinessReport({
    required this.id,
    required this.toiletId,
    required this.toiletQrCode,
    required this.toiletName,
    required this.reporterId,
    this.reporterRole = 'VARKARI',
    this.latitude,
    this.longitude,
    required this.issueType,
    required this.description,
    required this.reportedAt,
    required this.status,
    required this.priority,
    this.assignedCleanerId,
    this.assignedCleanerName,
    this.resolvedAt,
    this.resolutionNote,
    this.isDemo = true,
  });

  bool get isResolved => status == CleanlinessReportStatus.RESOLVED;
  bool get isHighPriority => priority == CleanlinessReportPriority.HIGH || priority == CleanlinessReportPriority.CRITICAL;

  CleanlinessReport copyWith({
    CleanlinessReportStatus? status,
    String? assignedCleanerId,
    String? assignedCleanerName,
    DateTime? resolvedAt,
    String? resolutionNote,
  }) {
    return CleanlinessReport(
      id: id,
      toiletId: toiletId,
      toiletQrCode: toiletQrCode,
      toiletName: toiletName,
      reporterId: reporterId,
      reporterRole: reporterRole,
      latitude: latitude,
      longitude: longitude,
      issueType: issueType,
      description: description,
      reportedAt: reportedAt,
      status: status ?? this.status,
      priority: priority,
      assignedCleanerId: assignedCleanerId ?? this.assignedCleanerId,
      assignedCleanerName: assignedCleanerName ?? this.assignedCleanerName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      isDemo: isDemo,
    );
  }

  factory CleanlinessReport.fromJson(Map<String, dynamic> json) => CleanlinessReport(
        id: json['id'] as String? ?? json['report_id'] as String? ?? '',
        toiletId: json['toilet_id'] as String? ?? '',
        toiletQrCode: json['toilet_qr_code'] as String? ?? '',
        toiletName: json['toilet_name'] as String? ?? 'Sanitation Facility',
        reporterId: json['reporter_id'] as String? ?? '',
        reporterRole: json['reporter_role'] as String? ?? 'VARKARI',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        issueType: CleanlinessIssueType.values.firstWhere(
          (e) => e.name == (json['issue_type'] as String? ?? json['category'] as String? ?? 'NEEDS_CLEANING'),
          orElse: () => CleanlinessIssueType.NEEDS_CLEANING,
        ),
        description: json['description'] as String? ?? '',
        reportedAt: DateTime.tryParse(json['reported_at'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
        status: CleanlinessReportStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'REPORTED'),
          orElse: () => CleanlinessReportStatus.REPORTED,
        ),
        priority: CleanlinessReportPriority.values.firstWhere(
          (e) => e.name == (json['priority'] as String? ?? 'MEDIUM'),
          orElse: () => CleanlinessReportPriority.MEDIUM,
        ),
        assignedCleanerId: json['assigned_cleaner_id'] as String? ?? json['assigned_worker_id'] as String?,
        assignedCleanerName: json['assigned_cleaner_name'] as String? ?? json['assigned_worker_name'] as String?,
        resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
        resolutionNote: json['resolution_note'] as String? ?? json['resolution_notes'] as String?,
        isDemo: json['is_demo'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'report_id': id,
        'toilet_id': toiletId,
        'toilet_qr_code': toiletQrCode,
        'toilet_name': toiletName,
        'reporter_id': reporterId,
        'reporter_role': reporterRole,
        'latitude': latitude,
        'longitude': longitude,
        'issue_type': issueType.name,
        'category': issueType.name,
        'description': description,
        'reported_at': reportedAt.toIso8601String(),
        'created_at': reportedAt.toIso8601String(),
        'status': status.name,
        'priority': priority.name,
        'assigned_cleaner_id': assignedCleanerId,
        'assigned_worker_id': assignedCleanerId,
        'assigned_cleaner_name': assignedCleanerName,
        'assigned_worker_name': assignedCleanerName,
        'resolved_at': resolvedAt?.toIso8601String(),
        'resolution_note': resolutionNote,
        'resolution_notes': resolutionNote,
        'is_demo': isDemo,
      };
}
