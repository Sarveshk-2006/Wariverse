import '../utils/app_logger.dart';
import '../../services/onesignal_service.dart';

/// Centralized Identity Bridge for WariVerse AI.
/// Enforces canonical 1:1 mapping: Firebase UID <-> Backend User ID <-> OneSignal External ID.
class IdentityBridge {
  static final IdentityBridge _instance = IdentityBridge._internal();
  factory IdentityBridge() => _instance;
  IdentityBridge._internal();

  String? _currentFirebaseUid;
  String? _currentBackendUserId;

  String? get currentFirebaseUid => _currentFirebaseUid;
  String? get currentBackendUserId => _currentBackendUserId;

  /// Binds authenticated session across Firebase Auth, Backend DB User, and OneSignal.
  Future<void> bindIdentity({
    required String firebaseUid,
    required String backendUserId,
  }) async {
    _currentFirebaseUid = firebaseUid;
    _currentBackendUserId = backendUserId;

    AppLogger.i('IdentityBridge: Bound Firebase UID ($firebaseUid) <-> Backend User ID ($backendUserId)');

    // Sync OneSignal external identity with authoritative backend user ID
    await OneSignalService().loginUser(backendUserId);
  }

  /// Clears identity associations on sign-out.
  Future<void> unbindIdentity() async {
    AppLogger.i('IdentityBridge: Unbinding identity session.');
    _currentFirebaseUid = null;
    _currentBackendUserId = null;
    await OneSignalService().logoutUser();
  }
}
