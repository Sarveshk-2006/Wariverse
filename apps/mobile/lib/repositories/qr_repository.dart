import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';
import '../models/qr_code_model.dart';

/// Production repository interfacing directly with Cloud Firestore `qr_codes` and `qr_scan_logs`.
class QrRepository {
  final FirebaseFirestore? _firestore;

  QrRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (EnvConfig.enableMockFallback ? null : FirebaseFirestore.instance);

  FirebaseFirestore? get firestore => _firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  // In-memory cache fallback when running offline or testing
  static final Map<String, WariQrCode> _localQrStore = {};
  static final List<WariQrScanLog> _localScanLogStore = [];

  /// Generate a secure, opaque QR record in Cloud Firestore `qr_codes/{qrId}`.
  Future<WariQrCode> generateQrCode({
    required QrType type,
    required String ownerId,
    required String targetCollection,
    required String targetDocumentId,
    required String createdBy,
    String? customPrefix,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final qrId = 'qr_${now.millisecondsSinceEpoch}_${now.microsecond % 1000}';
    final token = WariQrCode.generateSecureToken(customPrefix ?? type.name.substring(0, 3));

    final qrCode = WariQrCode(
      id: qrId,
      token: token,
      type: type,
      ownerId: ownerId,
      targetCollection: targetCollection,
      targetDocumentId: targetDocumentId,
      status: QrStatus.ACTIVE,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
      expiresAt: expiresAt?.toIso8601String(),
      createdBy: createdBy,
      scanCount: 0,
      metadata: metadata,
    );

    _localQrStore[qrCode.id] = qrCode;
    _localQrStore[token] = qrCode;

    final db = firestore;
    if (db != null) {
      try {
        await db.collection('qr_codes').doc(qrCode.id).set(qrCode.toJson());
        AppLogger.i('Created Firestore QR record ${qrCode.id} with token $token');
      } catch (e) {
        AppLogger.i('Notice: Cloud Firestore QR generation sync error: $e');
      }
    }

    return qrCode;
  }

  /// Retrieve existing active QR code by owner UID and type.
  Future<WariQrCode?> getQrByOwnerId(String ownerId, {QrType type = QrType.PERSON}) async {
    for (final qr in _localQrStore.values) {
      if (qr.ownerId == ownerId && qr.type == type && qr.isActive) {
        return qr;
      }
    }

    final db = firestore;
    if (db != null) {
      try {
        final query = await db
            .collection('qr_codes')
            .where('owner_id', isEqualTo: ownerId)
            .where('type', isEqualTo: type.name)
            .where('status', isEqualTo: QrStatus.ACTIVE.name)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final qr = WariQrCode.fromJson(query.docs.first.data());
          _localQrStore[qr.token] = qr;
          _localQrStore[qr.id] = qr;
          return qr;
        }
      } catch (e) {
        AppLogger.i('Notice: Firestore getQrByOwnerId error: $e');
      }
    }
    return null;
  }

  /// Retrieve existing QR code by token or target document ID.
  Future<WariQrCode?> getQrByToken(String rawToken) async {
    final token = WariQrCode.parseTokenFromRawPayload(rawToken);
    if (_localQrStore.containsKey(token)) {
      return _localQrStore[token];
    }

    final db = firestore;
    if (db != null) {
      try {
        final query = await db
            .collection('qr_codes')
            .where('token', isEqualTo: token)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final qr = WariQrCode.fromJson(query.docs.first.data());
          _localQrStore[token] = qr;
          _localQrStore[qr.id] = qr;
          return qr;
        }

        // Try direct document ID fallback
        final doc = await db.collection('qr_codes').doc(token).get();
        if (doc.exists && doc.data() != null) {
          final qr = WariQrCode.fromJson(doc.data()!);
          _localQrStore[token] = qr;
          _localQrStore[qr.id] = qr;
          return qr;
        }
      } catch (e) {
        AppLogger.i('Notice: Firestore getQrByToken error: $e');
      }
    }

    return null;
  }

  /// Realtime Cloud Firestore QR Validation Engine.
  Future<({
    WariQrCode? qrCode,
    QrScanResult result,
    String message,
  })> validateToken({
    required String rawToken,
    required String scannerUid,
    double? latitude,
    double? longitude,
    String? actionOverride,
  }) async {
    final token = rawToken.trim();
    final qrCode = await getQrByToken(token);

    final nowStr = DateTime.now().toIso8601String();
    final logId = 'scan_${DateTime.now().millisecondsSinceEpoch}';

    if (qrCode == null) {
      final log = WariQrScanLog(
        id: logId,
        qrId: 'UNKNOWN',
        token: token,
        qrType: QrType.PERSON,
        scannedBy: scannerUid,
        scannedAt: nowStr,
        result: QrScanResult.QR_NOT_FOUND,
        action: actionOverride ?? 'INVALID_TOKEN_SCAN',
        latitude: latitude,
        longitude: longitude,
      );
      await _logScan(log);

      return (
        qrCode: null,
        result: QrScanResult.QR_NOT_FOUND,
        message: QrScanResult.QR_NOT_FOUND.message,
      );
    }

    // Check status
    if (qrCode.status == QrStatus.REVOKED) {
      final log = WariQrScanLog(
        id: logId,
        qrId: qrCode.id,
        token: token,
        qrType: qrCode.type,
        scannedBy: scannerUid,
        scannedAt: nowStr,
        result: QrScanResult.QR_REVOKED,
        action: actionOverride ?? 'REVOKED_SCAN_ATTEMPT',
        latitude: latitude,
        longitude: longitude,
      );
      await _logScan(log);

      return (
        qrCode: qrCode,
        result: QrScanResult.QR_REVOKED,
        message: QrScanResult.QR_REVOKED.message,
      );
    }

    // Check expiration
    if (qrCode.expiresAt != null) {
      final exp = DateTime.tryParse(qrCode.expiresAt!);
      if (exp != null && DateTime.now().isAfter(exp)) {
        final log = WariQrScanLog(
          id: logId,
          qrId: qrCode.id,
          token: token,
          qrType: qrCode.type,
          scannedBy: scannerUid,
          scannedAt: nowStr,
          result: QrScanResult.QR_EXPIRED,
          action: actionOverride ?? 'EXPIRED_SCAN_ATTEMPT',
          latitude: latitude,
          longitude: longitude,
        );
        await _logScan(log);

        return (
          qrCode: qrCode,
          result: QrScanResult.QR_EXPIRED,
          message: QrScanResult.QR_EXPIRED.message,
        );
      }
    }

    // Valid Scan -> Increment count and log audit
    final updatedQr = qrCode.copyWith(
      lastScannedAt: nowStr,
      lastScannedBy: scannerUid,
      scanCount: qrCode.scanCount + 1,
    );

    _localQrStore[updatedQr.id] = updatedQr;
    _localQrStore[token] = updatedQr;

    final db = firestore;
    if (db != null) {
      try {
        await db.collection('qr_codes').doc(updatedQr.id).update({
          'last_scanned_at': nowStr,
          'last_scanned_by': scannerUid,
          'scan_count': FieldValue.increment(1),
          'updated_at': nowStr,
        });
      } catch (e) {
        AppLogger.i('Notice: Firestore scan_count update error: $e');
      }
    }

    final validLog = WariQrScanLog(
      id: logId,
      qrId: updatedQr.id,
      token: token,
      qrType: updatedQr.type,
      scannedBy: scannerUid,
      scannedAt: nowStr,
      result: QrScanResult.QR_VALID,
      action: actionOverride ?? 'AUTHORIZATION_VERIFIED',
      latitude: latitude,
      longitude: longitude,
    );
    await _logScan(validLog);

    return (
      qrCode: updatedQr,
      result: QrScanResult.QR_VALID,
      message: QrScanResult.QR_VALID.message,
    );
  }

  /// Write scan audit record to `qr_scan_logs/{scanId}` collection.
  Future<void> _logScan(WariQrScanLog log) async {
    _localScanLogStore.add(log);

    final db = firestore;
    if (db != null) {
      try {
        await db.collection('qr_scan_logs').doc(log.id).set(log.toJson());
      } catch (e) {
        AppLogger.i('Notice: Firestore qr_scan_logs audit error: $e');
      }
    }
  }

  /// Revoke an active QR code (`status = REVOKED`).
  Future<bool> revokeQrCode(String qrId, String actorUid) async {
    final existing = _localQrStore[qrId];
    if (existing != null) {
      final revoked = existing.copyWith(status: QrStatus.REVOKED);
      _localQrStore[qrId] = revoked;
      _localQrStore[existing.token] = revoked;
    }

    final db = firestore;
    if (db != null) {
      try {
        await db.collection('qr_codes').doc(qrId).update({
          'status': 'REVOKED',
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      } catch (e) {
        AppLogger.i('Notice: Firestore revoke error: $e');
        return false;
      }
    }
    return true;
  }

  /// Regenerate QR code token (invalidates old token, creates fresh WVQ_... token).
  Future<WariQrCode?> regenerateQrCode(String qrId, String actorUid) async {
    await revokeQrCode(qrId, actorUid);
    final existing = _localQrStore[qrId];
    if (existing == null) return null;

    return await generateQrCode(
      type: existing.type,
      ownerId: existing.ownerId,
      targetCollection: existing.targetCollection,
      targetDocumentId: existing.targetDocumentId,
      createdBy: actorUid,
      metadata: existing.metadata,
    );
  }

  /// Fetch scan audit logs for a given QR ID.
  Future<List<WariQrScanLog>> getScanLogsForQr(String qrId) async {
    final db = firestore;
    if (db != null) {
      try {
        final query = await db
            .collection('qr_scan_logs')
            .where('qr_id', isEqualTo: qrId)
            .orderBy('scanned_at', descending: true)
            .get();

        return query.docs.map((d) => WariQrScanLog.fromJson(d.data())).toList();
      } catch (e) {
        AppLogger.i('Notice: Firestore getScanLogs error: $e');
      }
    }

    return _localScanLogStore.where((l) => l.qrId == qrId).toList();
  }
}
