import 'package:flutter/material.dart';
import '../models/models_exports.dart';
import '../repositories/qr_repository.dart';
import '../core/utils/app_logger.dart';

/// Provider for managing production WariVerse QR generation, realtime validation, revocation, and scan history.
class QrProvider extends ChangeNotifier {
  final QrRepository _qrRepo;

  bool _isValidating = false;
  bool _isGenerating = false;
  QrScanResult? _lastScanResult;
  String? _lastScanMessage;
  WariQrCode? _lastScannedQr;
  WariQrCode? _activeUserQr;
  List<WariQrScanLog> _activeScanLogs = [];

  QrProvider({QrRepository? qrRepo}) : _qrRepo = qrRepo ?? QrRepository();

  bool get isValidating => _isValidating;
  bool get isGenerating => _isGenerating;
  QrScanResult? get lastScanResult => _lastScanResult;
  String? get lastScanMessage => _lastScanMessage;
  WariQrCode? get lastScannedQr => _lastScannedQr;
  WariQrCode? get activeUserQr => _activeUserQr;
  List<WariQrScanLog> get activeScanLogs => _activeScanLogs;

  /// Clear scanner state before opening camera viewfinder.
  void clearScanState() {
    _isValidating = false;
    _lastScanResult = null;
    _lastScanMessage = null;
    _lastScannedQr = null;
    notifyListeners();
  }

  /// Get or create Digital Pilgrim ID QR for current user (persisted & stable identity).
  Future<WariQrCode> getOrCreatePilgrimIdQr(String userId) async {
    if (_activeUserQr != null && _activeUserQr!.ownerId == userId && _activeUserQr!.isActive) {
      return _activeUserQr!;
    }

    _isGenerating = true;

    try {
      final existing = await _qrRepo.getQrByOwnerId(userId, type: QrType.PERSON);
      if (existing != null && existing.isActive) {
        _activeUserQr = existing;
        _isGenerating = false;
        notifyListeners();
        return existing;
      }

      final newQr = await _qrRepo.generateQrCode(
        type: QrType.PERSON,
        ownerId: userId,
        targetCollection: 'users',
        targetDocumentId: userId,
        createdBy: userId,
        customPrefix: 'WVRK',
        metadata: {'user_id': userId, 'title': 'Digital Pilgrim Identity Card'},
      );

      _activeUserQr = newQr;
      _isGenerating = false;
      notifyListeners();
      return newQr;
    } catch (e) {
      _isGenerating = false;
      AppLogger.i('Error generating pilgrim ID QR: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Realtime Cloud Firestore Token Validation.
  Future<({
    WariQrCode? qrCode,
    QrScanResult result,
    String message,
  })> validateScannedToken({
    required String rawToken,
    required String scannerUid,
    double? latitude,
    double? longitude,
    String? actionOverride,
  }) async {
    _isValidating = true;
    _lastScanResult = null;
    _lastScanMessage = null;
    _lastScannedQr = null;
    notifyListeners();

    try {
      final res = await _qrRepo.validateToken(
        rawToken: rawToken,
        scannerUid: scannerUid,
        latitude: latitude,
        longitude: longitude,
        actionOverride: actionOverride,
      );

      _isValidating = false;
      _lastScanResult = res.result;
      _lastScanMessage = res.message;
      _lastScannedQr = res.qrCode;

      if (res.qrCode != null) {
        _loadScanLogs(res.qrCode!.id);
      }

      notifyListeners();
      return res;
    } catch (e) {
      _isValidating = false;
      _lastScanResult = QrScanResult.QR_NOT_FOUND;
      _lastScanMessage = 'Validation error: ${e.toString()}';
      notifyListeners();
      return (
        qrCode: null,
        result: QrScanResult.QR_NOT_FOUND,
        message: _lastScanMessage!,
      );
    }
  }

  /// Generate a custom QR for Lost Person, Toilet, Resource, etc.
  Future<WariQrCode> generateCustomQr({
    required QrType type,
    required String ownerId,
    required String targetCollection,
    required String targetDocumentId,
    required String createdBy,
    String? customPrefix,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    _isGenerating = true;
    notifyListeners();

    final qr = await _qrRepo.generateQrCode(
      type: type,
      ownerId: ownerId,
      targetCollection: targetCollection,
      targetDocumentId: targetDocumentId,
      createdBy: createdBy,
      customPrefix: customPrefix,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    _isGenerating = false;
    notifyListeners();
    return qr;
  }

  /// Revoke QR code.
  Future<bool> revokeQr(String qrId, String actorUid) async {
    final success = await _qrRepo.revokeQrCode(qrId, actorUid);
    if (success && _activeUserQr?.id == qrId) {
      _activeUserQr = _activeUserQr!.copyWith(status: QrStatus.REVOKED);
    }
    notifyListeners();
    return success;
  }

  /// Regenerate QR code.
  Future<WariQrCode?> regenerateQr(String qrId, String actorUid) async {
    final newQr = await _qrRepo.regenerateQrCode(qrId, actorUid);
    if (newQr != null && newQr.ownerId == actorUid) {
      _activeUserQr = newQr;
    }
    notifyListeners();
    return newQr;
  }

  /// Load audit logs for a QR code.
  Future<void> _loadScanLogs(String qrId) async {
    _activeScanLogs = await _qrRepo.getScanLogsForQr(qrId);
    notifyListeners();
  }
}
