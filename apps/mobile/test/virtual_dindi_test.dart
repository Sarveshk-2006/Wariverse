import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/virtual_dindi_model.dart';
import 'package:mobile/core/utils/virtual_dindi_engine.dart';
import 'package:mobile/services/virtual_dindi_local_service.dart';
import 'package:mobile/repositories/virtual_dindi_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('VirtualDindi Engine & Geospatial Tests', () {
    test('Haversine distance calculates accurate distance between two GPS points', () {
      // Distance between Pune Shaniwar Wada (18.5196, 73.8553) and Alandi (18.6773, 73.8967) is ~18.1 km
      final distMeters = VirtualDindiEngine.haversineDistance(18.5196, 73.8553, 18.6773, 73.8967);
      expect(distMeters, greaterThan(17500));
      expect(distMeters, lessThan(18500));

      // Same point distance must be zero
      final samePoint = VirtualDindiEngine.haversineDistance(18.5204, 73.8567, 18.5204, 73.8567);
      expect(samePoint, equals(0.0));
    });

    test('calculateRobustGroupCenter filters stale and low-accuracy GPS readings', () {
      final now = DateTime.now();

      final members = [
        // Valid active member 1
        VirtualDindiMember(
          uid: 'm1',
          displayName: 'Valid 1',
          joinedAt: now.toIso8601String(),
          lastLatitude: 18.5200,
          lastLongitude: 73.8560,
          accuracyMeters: 10.0,
          lastLocationAt: now.toIso8601String(),
          lastOnlineAt: now.toIso8601String(),
        ),
        // Valid active member 2
        VirtualDindiMember(
          uid: 'm2',
          displayName: 'Valid 2',
          joinedAt: now.toIso8601String(),
          lastLatitude: 18.5210,
          lastLongitude: 73.8570,
          accuracyMeters: 15.0,
          lastLocationAt: now.toIso8601String(),
          lastOnlineAt: now.toIso8601String(),
        ),
        // Stale location member (>20 mins old) -> MUST BE IGNORED
        VirtualDindiMember(
          uid: 'm3_stale',
          displayName: 'Stale Member',
          joinedAt: now.toIso8601String(),
          lastLatitude: 19.9999,
          lastLongitude: 74.9999,
          accuracyMeters: 10.0,
          lastLocationAt: now.subtract(const Duration(minutes: 25)).toIso8601String(),
          lastOnlineAt: now.toIso8601String(),
        ),
        // Inaccurate GPS member (accuracy = 150m) -> MUST BE IGNORED
        VirtualDindiMember(
          uid: 'm4_inaccurate',
          displayName: 'Inaccurate GPS Member',
          joinedAt: now.toIso8601String(),
          lastLatitude: 19.9999,
          lastLongitude: 74.9999,
          accuracyMeters: 150.0,
          lastLocationAt: now.toIso8601String(),
          lastOnlineAt: now.toIso8601String(),
        ),
      ];

      final groupCenter = VirtualDindiEngine.calculateRobustGroupCenter(members);

      expect(groupCenter.activeContributingMembers, equals(2));
      expect(groupCenter.isReliable, isTrue);
      expect(groupCenter.latitude, closeTo(18.5205, 0.001));
      expect(groupCenter.longitude, closeTo(73.8565, 0.001));
    });

    test('evaluateMemberSeparation evaluates thresholds and trend correctly', () {
      final now = DateTime.now();

      // Test 1: SAFE distance (50m)
      final evalSafe = VirtualDindiEngine.evaluateMemberSeparation(
        memberLat: 18.5204,
        memberLng: 73.8567,
        accuracyMeters: 10.0,
        groupCenterLat: 18.5204,
        groupCenterLng: 73.8567,
        currentPreviousState: SeparationState.SAFE,
        stateEnteredAt: now,
        previousDistanceMeters: 0.0,
      );
      expect(evalSafe.separationState, equals(SeparationState.SAFE));

      // Test 2: CAUTION distance (100m)
      final evalCaution = VirtualDindiEngine.evaluateMemberSeparation(
        memberLat: 18.5213,
        memberLng: 73.8567,
        accuracyMeters: 10.0,
        groupCenterLat: 18.5204,
        groupCenterLng: 73.8567,
        currentPreviousState: SeparationState.SAFE,
        stateEnteredAt: now,
        previousDistanceMeters: 50.0,
      );
      expect(evalCaution.separationState, equals(SeparationState.CAUTION));
      expect(evalCaution.trend, equals(MovementTrend.MOVING_AWAY));

      // Test 3: RETURNING trend when distance decreases
      final evalReturning = VirtualDindiEngine.evaluateMemberSeparation(
        memberLat: 18.5208,
        memberLng: 73.8567,
        accuracyMeters: 10.0,
        groupCenterLat: 18.5204,
        groupCenterLng: 73.8567,
        currentPreviousState: SeparationState.SEPARATED,
        stateEnteredAt: now,
        previousDistanceMeters: 200.0,
      );
      expect(evalReturning.trend, equals(MovementTrend.RETURNING));
    });
  });

  group('VirtualDindi Model & Serialization Tests', () {
    test('VirtualDindi and Member JSON roundtrip works reliably', () {
      final dindi = VirtualDindi(
        dindiId: 'vd_test_1001',
        name: 'Alandi Mauli Dindi',
        description: 'Test Group',
        joinCode: 'VDND-9999',
        leaderUid: 'leader_uid_77',
        leaderName: 'Leader Vitthal',
        status: VirtualDindiStatus.ACTIVE,
        createdAt: '2026-08-29T23:00:00.000Z',
        updatedAt: '2026-08-29T23:00:00.000Z',
        meetingPointLat: 18.5204,
        meetingPointLng: 73.8567,
        meetingPointName: 'Palkhi Pavilion',
        safeRadiusMeters: 75.0,
        separationThresholdMeters: 150.0,
        criticalThresholdMeters: 300.0,
        activeMemberCount: 5,
      );

      final json = dindi.toJson();
      final rebuilt = VirtualDindi.fromJson(json);

      expect(rebuilt.dindiId, equals('vd_test_1001'));
      expect(rebuilt.joinCode, equals('VDND-9999'));
      expect(rebuilt.qrToken, equals('WV_DINDI:vd_test_1001'));
      expect(rebuilt.status, equals(VirtualDindiStatus.ACTIVE));
      expect(rebuilt.safeRadiusMeters, equals(75.0));
      expect(rebuilt.activeMemberCount, equals(5));
    });

    test('VirtualDindiLocalService queues and retrieves offline events cleanly', () async {
      final event = VirtualDindiEvent(
        eventId: 'evt_offline_001',
        dindiId: 'vd_offline_99',
        type: VirtualDindiEventType.MEMBER_SEPARATED,
        actorUid: 'varkari_01',
        targetUid: 'varkari_01',
        details: 'Separation detected offline',
        timestamp: DateTime.now().toIso8601String(),
        createdOffline: true,
      );

      await VirtualDindiLocalService.queueOfflineEvent(event);
      final queued = await VirtualDindiLocalService.getQueuedOfflineEvents();

      expect(queued, isNotEmpty);
      expect(queued.any((e) => e.eventId == 'evt_offline_001'), isTrue);

      await VirtualDindiLocalService.clearQueuedOfflineEvents();
      final cleared = await VirtualDindiLocalService.getQueuedOfflineEvents();
      expect(cleared, isEmpty);
    });

    test('VirtualDindiRepository join duplicate protection and leave flow', () async {
      final repo = VirtualDindiRepository();

      // Create Dindi
      final dindi = await repo.createVirtualDindi(
        name: 'Pandharpur Express',
        description: 'Test Group',
        leaderUid: 'leader_uid_001',
        leaderName: 'Leader Vitthal',
        meetingPointLat: 18.5204,
        meetingPointLng: 73.8567,
        meetingPointName: 'Palkhi Mandap',
      );

      expect(dindi.activeMemberCount, equals(1));

      // Join first time with User A
      final joined1 = await repo.joinVirtualDindi(
        codeOrId: dindi.joinCode,
        uid: 'user_a_123',
        displayName: 'User A',
        role: 'VARKARI',
        currentLat: 18.5204,
        currentLng: 73.8567,
      );
      expect(joined1, isNotNull);

      // Duplicate join with User A (same UID) must NOT throw and preserve member identity
      final joined2 = await repo.joinVirtualDindi(
        codeOrId: dindi.joinCode,
        uid: 'user_a_123',
        displayName: 'User A',
        role: 'VARKARI',
        currentLat: 18.5204,
        currentLng: 73.8567,
      );
      expect(joined2, isNotNull);

      // User A leaves Dindi
      await repo.leaveVirtualDindi(
        dindiId: dindi.dindiId,
        uid: 'user_a_123',
        displayName: 'User A',
      );

      // Verify active local dindi is cleared on leave
      final activeLocal = await VirtualDindiLocalService.getActiveDindi();
      expect(activeLocal, isNull);
    });
  });
}
