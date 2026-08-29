// ignore_for_file: constant_identifier_names
import 'dart:math';

/// Supported production QR code domain types in WariVerse AI.
enum QrType {
  PERSON,
  LOST_PERSON,
  TOILET,
  CLEANING_TASK,
  DINDI,
  RESOURCE,
  MEDICAL,
  SHELTER,
  WATER,
  FOOD,
  EMERGENCY,
}

extension QrTypeX on QrType {
  String get displayName {
    switch (this) {
      case QrType.PERSON:        return 'Digital Pilgrim ID';
      case QrType.LOST_PERSON:   return 'Lost Person Tag';
      case QrType.TOILET:        return 'CleanWari Toilet Facility';
      case QrType.CLEANING_TASK: return 'Sanitation Task';
      case QrType.DINDI:         return 'Dindi Membership';
      case QrType.RESOURCE:      return 'NGO Aid Resource';
      case QrType.MEDICAL:       return 'Medical Center';
      case QrType.SHELTER:       return 'Pilgrim Shelter';
      case QrType.WATER:         return 'Water Distribution';
      case QrType.FOOD:          return 'Food Centre';
      case QrType.EMERGENCY:     return 'Emergency SOS Tag';
    }
  }

  static QrType fromString(String str) {
    final upper = str.trim().toUpperCase();
    return QrType.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => QrType.PERSON,
    );
  }
}

/// QR Status Lifecycle.
enum QrStatus {
  ACTIVE,
  REVOKED,
  EXPIRED,
}

extension QrStatusX on QrStatus {
  static QrStatus fromString(String str) {
    final upper = str.trim().toUpperCase();
    return QrStatus.values.firstWhere(
      (e) => e.name == upper,
      orElse: () => QrStatus.ACTIVE,
    );
  }
}

/// Firebase Realtime Scan Validation Result.
enum QrScanResult {
  QR_VALID,
  QR_NOT_FOUND,
  QR_REVOKED,
  QR_EXPIRED,
  QR_UNAUTHORIZED,
}

extension QrScanResultX on QrScanResult {
  String get message {
    switch (this) {
      case QrScanResult.QR_VALID:        return '✓ Valid WariVerse QR Code';
      case QrScanResult.QR_NOT_FOUND:    return '⚠️ Invalid WariVerse QR code (Not found)';
      case QrScanResult.QR_REVOKED:      return '🚫 QR Code has been revoked by owner or administrator';
      case QrScanResult.QR_EXPIRED:      return '⏳ QR Code has expired';
      case QrScanResult.QR_UNAUTHORIZED: return '🔒 Access Denied: You are not authorized to perform this QR action';
    }
  }
}

/// Production domain model for Cloud Firestore `qr_codes/{qrId}`.
class WariQrCode {
  final String id;
  final String token; // WVQ_<secure-random-token>
  final QrType type;
  final String ownerId;
  final String targetCollection;
  final String targetDocumentId;
  final QrStatus status;
  final String createdAt;
  final String updatedAt;
  final String? expiresAt;
  final String createdBy;
  final String? lastScannedAt;
  final String? lastScannedBy;
  final int scanCount;
  final Map<String, dynamic>? metadata;

  const WariQrCode({
    required this.id,
    required this.token,
    required this.type,
    required this.ownerId,
    required this.targetCollection,
    required this.targetDocumentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    required this.createdBy,
    this.lastScannedAt,
    this.lastScannedBy,
    this.scanCount = 0,
    this.metadata,
  });

  bool get isActive => status == QrStatus.ACTIVE;

  /// Safe short display identifier shielding PII (e.g. WVRK-A1B2C3).
  String get shortDisplayId {
    final cleanToken = token.replaceAll('WVRK:', '').replaceAll('WVQ_', '').replaceAll('WVQ_PERSON_', '');
    if (cleanToken.length >= 6) {
      return 'WVRK-${cleanToken.substring(0, 6).toUpperCase()}';
    }
    return 'WVRK-${cleanToken.toUpperCase()}';
  }

  /// Helper to generate a cryptographically random, non-guessable secure token.
  static String generateSecureToken([String? prefix]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(12, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (prefix == null || prefix.trim().isEmpty || prefix.toUpperCase() == 'WVRK') {
      return 'WVRK:$hex';
    }
    final p = prefix.trim().toUpperCase();
    if (p.contains(':')) return '${p}_$hex';
    return '${p}_$hex';
  }

  /// Extract clean token identifier from raw scanned camera string (URL, deep-link, or WVRK: token).
  static String parseTokenFromRawPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last.trim();
      }
    }
    return trimmed;
  }

  factory WariQrCode.fromJson(Map<String, dynamic> json) {
    return WariQrCode(
      id: json['id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      type: QrTypeX.fromString(json['type'] as String? ?? 'PERSON'),
      ownerId: json['owner_id'] as String? ?? '',
      targetCollection: json['target_collection'] as String? ?? '',
      targetDocumentId: json['target_document_id'] as String? ?? '',
      status: QrStatusX.fromString(json['status'] as String? ?? 'ACTIVE'),
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      expiresAt: json['expires_at'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      lastScannedAt: json['last_scanned_at'] as String?,
      lastScannedBy: json['last_scanned_by'] as String?,
      scanCount: json['scan_count'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'type': type.name,
      'owner_id': ownerId,
      'target_collection': targetCollection,
      'target_document_id': targetDocumentId,
      'status': status.name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'expires_at': expiresAt,
      'created_by': createdBy,
      'last_scanned_at': lastScannedAt,
      'last_scanned_by': lastScannedBy,
      'scan_count': scanCount,
      if (metadata != null) 'metadata': metadata,
    };
  }

  WariQrCode copyWith({
    QrStatus? status,
    String? token,
    String? updatedAt,
    String? lastScannedAt,
    String? lastScannedBy,
    int? scanCount,
  }) {
    return WariQrCode(
      id: id,
      token: token ?? this.token,
      type: type,
      ownerId: ownerId,
      targetCollection: targetCollection,
      targetDocumentId: targetDocumentId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
      expiresAt: expiresAt,
      createdBy: createdBy,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      lastScannedBy: lastScannedBy ?? this.lastScannedBy,
      scanCount: scanCount ?? this.scanCount,
      metadata: metadata,
    );
  }
}

/// Production domain model for Cloud Firestore `qr_scan_logs/{scanId}`.
class WariQrScanLog {
  final String id;
  final String qrId;
  final String token;
  final QrType qrType;
  final String scannedBy;
  final String scannedAt;
  final QrScanResult result;
  final String action;
  final double? latitude;
  final double? longitude;

  const WariQrScanLog({
    required this.id,
    required this.qrId,
    required this.token,
    required this.qrType,
    required this.scannedBy,
    required this.scannedAt,
    required this.result,
    required this.action,
    this.latitude,
    this.longitude,
  });

  factory WariQrScanLog.fromJson(Map<String, dynamic> json) {
    return WariQrScanLog(
      id: json['id'] as String? ?? '',
      qrId: json['qr_id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      qrType: QrTypeX.fromString(json['qr_type'] as String? ?? 'PERSON'),
      scannedBy: json['scanned_by'] as String? ?? '',
      scannedAt: json['scanned_at'] as String? ?? DateTime.now().toIso8601String(),
      result: QrScanResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => QrScanResult.QR_NOT_FOUND,
      ),
      action: json['action'] as String? ?? 'SCAN',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qr_id': qrId,
      'token': token,
      'qr_type': qrType.name,
      'scanned_by': scannedBy,
      'scanned_at': scannedAt,
      'result': result.name,
      'action': action,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
