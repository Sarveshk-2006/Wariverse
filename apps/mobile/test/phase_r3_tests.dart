import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models_exports.dart';

import 'package:mobile/core/permissions/role_permission_matrix.dart';
import 'package:mobile/core/auth/identity_bridge.dart';
import 'package:mobile/core/network/realtime_connection_state.dart';
import 'package:mobile/services/realtime_service.dart';
import 'package:mobile/services/onesignal_service.dart';
import 'package:mobile/services/notification_navigation_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase R3 & M9 & M10-B Realtime & Identity Foundation Tests', () {
    test('RolePermissionMatrix strictly isolates admin access', () {
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.VARKARI), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.DINDI_LEADER), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.VOLUNTEER), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.MEDICAL_TEAM), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.POLICE), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.NGO), false);
      expect(RolePermissionMatrix.canAccessAdmin(UserRole.ADMIN), true);
    });

    test('RolePermissionMatrix restricts Dindi Leader access to authorized roles', () {
      expect(RolePermissionMatrix.canAccessDindiLeader(UserRole.VARKARI), false);
      expect(RolePermissionMatrix.canAccessDindiLeader(UserRole.DINDI_LEADER), true);
      expect(RolePermissionMatrix.canAccessDindiLeader(UserRole.ADMIN), true);
    });

    test('IdentityBridge binds Firebase UID and Backend User ID correctly', () async {
      final bridge = IdentityBridge();
      await bridge.bindIdentity(firebaseUid: 'firebase-uid-12345', backendUserId: 'user-uuid-67890');
      expect(bridge.currentFirebaseUid, 'firebase-uid-12345');
      expect(bridge.currentBackendUserId, 'user-uuid-67890');
      await bridge.unbindIdentity();
      expect(bridge.currentFirebaseUid, null);
      expect(bridge.currentBackendUserId, null);
    });

    test('FirestoreRealtimeService manages connection lifecycle state transition', () {
      final service = FirestoreRealtimeService();
      expect(service.connectionState, RealtimeConnectionState.live);
      service.updateConnectionState(RealtimeConnectionState.reconnecting);
      expect(service.connectionState, RealtimeConnectionState.reconnecting);
      service.updateConnectionState(RealtimeConnectionState.live);
      expect(service.connectionState, RealtimeConnectionState.live);
    });

    test('OneSignalService initializes gracefully when given target app ID', () async {
      final service = OneSignalService();
      await service.initialize(appId: 'd3eb187f-c8cc-49a2-baf7-75724f14874d');
      expect(service.isInitialized, true);
    });

    test('isServerAssignedSubscriptionId rejects empty or local placeholder IDs', () {
      expect(OneSignalService.isServerAssignedSubscriptionId(null), false);
      expect(OneSignalService.isServerAssignedSubscriptionId(''), false);
      expect(OneSignalService.isServerAssignedSubscriptionId('local-1234-5678'), false);
      expect(OneSignalService.isServerAssignedSubscriptionId('8f7e6d5c-4b3a-2109-8765-43210fedcba9'), true);
    });

    test('NotificationNavigationHandler handles null or malformed payloads safely without crashing', () {
      final handler = NotificationNavigationHandler();
      expect(() => handler.handleNotificationPayload(null), returnsNormally);
      expect(() => handler.handleNotificationPayload({}), returnsNormally);
      expect(() => handler.handleNotificationPayload({'type': 'UNKNOWN', 'route': '/invalid'}), returnsNormally);
    });
  });
}
