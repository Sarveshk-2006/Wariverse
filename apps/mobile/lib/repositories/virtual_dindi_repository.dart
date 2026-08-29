import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/virtual_dindi_model.dart';
import '../services/virtual_dindi_local_service.dart';
import '../core/utils/app_logger.dart';

/// Repository managing Cloud Firestore persistence and synchronization for Virtual Dindis.
class VirtualDindiRepository {
  late final FirebaseFirestore? _firestore;

  VirtualDindiRepository({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      _firestore = firestore;
    } else {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (_) {
        _firestore = null;
      }
    }
  }

  /// Creates a new Virtual Dindi in Firestore.
  Future<VirtualDindi> createVirtualDindi({
    required String name,
    required String description,
    required String leaderUid,
    required String leaderName,
    required double meetingPointLat,
    required double meetingPointLng,
    required String meetingPointName,
    double safeRadiusMeters = 75.0,
    double separationThresholdMeters = 150.0,
    double criticalThresholdMeters = 300.0,
  }) async {
    final String dindiId = _firestore?.collection('virtual_dindis').doc().id ?? 'vd_${DateTime.now().millisecondsSinceEpoch}';

    // Generate unique short 4-digit join code: VDND-XXXX
    final String joinCode = 'VDND-${(dindiId.hashCode.abs() % 9000 + 1000)}';
    final now = DateTime.now().toIso8601String();

    final dindi = VirtualDindi(
      dindiId: dindiId,
      name: name,
      description: description,
      joinCode: joinCode,
      leaderUid: leaderUid,
      leaderName: leaderName,
      status: VirtualDindiStatus.ACTIVE,
      createdAt: now,
      updatedAt: now,
      meetingPointLat: meetingPointLat,
      meetingPointLng: meetingPointLng,
      meetingPointName: meetingPointName,
      safeRadiusMeters: safeRadiusMeters,
      separationThresholdMeters: separationThresholdMeters,
      criticalThresholdMeters: criticalThresholdMeters,
      activeMemberCount: 1,
    );

    // Save main document
    if (_firestore != null) {
      final dindiRef = _firestore.collection('virtual_dindis').doc(dindiId);
      await dindiRef.set(dindi.toJson());
    }

    // Add Leader as first member
    final leaderMember = VirtualDindiMember(
      uid: leaderUid,
      displayName: leaderName,
      role: 'DINDI_LEADER',
      joinedAt: now,
      memberStatus: 'ACTIVE',
      lastLatitude: meetingPointLat,
      lastLongitude: meetingPointLng,
      accuracyMeters: 10.0,
      lastLocationAt: now,
      isInsideDindi: true,
      distanceFromGroupMeters: 0.0,
      separationState: SeparationState.SAFE,
      trend: MovementTrend.STABLE_SEPARATION,
      lastOnlineAt: now,
      isLeader: true,
    );

    if (_firestore != null) {
      await _firestore.collection('virtual_dindis').doc(dindiId).collection('members').doc(leaderUid).set(leaderMember.toJson());
    }

    // Log Creation Event
    await logEvent(
      dindiId: dindiId,
      type: VirtualDindiEventType.DINDI_STARTED,
      actorUid: leaderUid,
      targetUid: leaderUid,
      details: 'Virtual Dindi "$name" created by $leaderName.',
      latitude: meetingPointLat,
      longitude: meetingPointLng,
    );

    // Cache locally
    await VirtualDindiLocalService.saveActiveDindi(dindi);
    await VirtualDindiLocalService.saveMembers([leaderMember]);

    AppLogger.i('Created Virtual Dindi "$name" with ID: $dindiId, Code: $joinCode');
    return dindi;
  }

  /// Join an existing Virtual Dindi via Join Code or Dindi ID.
  Future<VirtualDindi?> joinVirtualDindi({
    required String codeOrId,
    required String uid,
    required String displayName,
    required String role,
    required double currentLat,
    required double currentLng,
  }) async {
    final cleanCode = codeOrId.trim().toUpperCase();

    if (_firestore == null) {
      final cached = await VirtualDindiLocalService.getActiveDindi();
      if (cached != null) {
        return cached;
      }
      return null;
    }

    // Query by join_code or document id
    QuerySnapshot snapshot = await _firestore
        .collection('virtual_dindis')
        .where('join_code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    DocumentSnapshot? doc;
    if (snapshot.docs.isNotEmpty) {
      doc = snapshot.docs.first;
    } else {
      final directDoc = await _firestore.collection('virtual_dindis').doc(cleanCode).get();
      if (directDoc.exists) doc = directDoc;
    }

    if (doc == null || !doc.exists) {
      AppLogger.i('No active Virtual Dindi found for code/ID: $cleanCode');
      return null;
    }

    final dindi = VirtualDindi.fromJson(doc.data() as Map<String, dynamic>);
    if (dindi.status == VirtualDindiStatus.ENDED) {
      throw Exception('This Virtual Dindi session has ended.');
    }

    final now = DateTime.now().toIso8601String();

    final memberDocRef = _firestore
        .collection('virtual_dindis')
        .doc(dindi.dindiId)
        .collection('members')
        .doc(uid);

    final existingDoc = await memberDocRef.get();
    final data = existingDoc.data();
    final bool isAlreadyActive = existingDoc.exists && (data?['member_status'] == 'ACTIVE');

    final member = VirtualDindiMember(
      uid: uid,
      displayName: displayName,
      role: role,
      joinedAt: existingDoc.exists ? (data?['joined_at'] as String? ?? now) : now,
      memberStatus: 'ACTIVE',
      lastLatitude: currentLat,
      lastLongitude: currentLng,
      accuracyMeters: 10.0,
      lastLocationAt: now,
      isInsideDindi: true,
      distanceFromGroupMeters: 0.0,
      separationState: SeparationState.SAFE,
      trend: MovementTrend.STABLE_SEPARATION,
      lastOnlineAt: now,
      isLeader: dindi.leaderUid == uid,
    );

    // Write membership
    await memberDocRef.set(member.toJson(), SetOptions(merge: true));

    // Only increment active_member_count if member was NOT already active
    if (!isAlreadyActive) {
      await _firestore.collection('virtual_dindis').doc(dindi.dindiId).update({
        'active_member_count': FieldValue.increment(1),
        'updated_at': now,
      });

      // Log Joined Event
      await logEvent(
        dindiId: dindi.dindiId,
        type: VirtualDindiEventType.MEMBER_JOINED,
        actorUid: uid,
        targetUid: uid,
        details: '$displayName joined ${dindi.name}.',
        latitude: currentLat,
        longitude: currentLng,
      );
    }

    await VirtualDindiLocalService.saveActiveDindi(dindi);
    AppLogger.i('$displayName joined Virtual Dindi ${dindi.dindiId}');

    return dindi;
  }

  /// Leave Virtual Dindi for a member. Updates member status to INACTIVE and decrements participant count.
  Future<void> leaveVirtualDindi({
    required String dindiId,
    required String uid,
    required String displayName,
  }) async {
    await VirtualDindiLocalService.clearActiveDindi();

    if (_firestore == null) {
      AppLogger.i('$displayName left Virtual Dindi $dindiId (offline mode)');
      return;
    }
    final now = DateTime.now().toIso8601String();

    final memberDocRef = _firestore
        .collection('virtual_dindis')
        .doc(dindiId)
        .collection('members')
        .doc(uid);

    final existingDoc = await memberDocRef.get();
    if (existingDoc.exists) {
      final data = existingDoc.data();
      if (data != null && data['member_status'] == 'ACTIVE') {
        await memberDocRef.update({
          'member_status': 'INACTIVE',
          'is_inside_dindi': false,
          'left_at': now,
          'last_online_at': now,
        });

        await _firestore.collection('virtual_dindis').doc(dindiId).update({
          'active_member_count': FieldValue.increment(-1),
          'updated_at': now,
        });

        await logEvent(
          dindiId: dindiId,
          type: VirtualDindiEventType.MEMBER_LEFT,
          actorUid: uid,
          targetUid: uid,
          details: '$displayName left Virtual Dindi.',
        );
      }
    }

    await VirtualDindiLocalService.clearActiveDindi();
    AppLogger.i('$displayName left Virtual Dindi $dindiId');
  }

  /// Leader Control: Remove a member from the Virtual Dindi.
  Future<void> removeMember({
    required String dindiId,
    required String targetUid,
    required String leaderUid,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();

    final memberDocRef = _firestore
        .collection('virtual_dindis')
        .doc(dindiId)
        .collection('members')
        .doc(targetUid);

    final existingDoc = await memberDocRef.get();
    if (existingDoc.exists) {
      final data = existingDoc.data();
      if (data != null && data['member_status'] == 'ACTIVE') {
        final targetName = data['display_name'] as String? ?? 'Member';

        await memberDocRef.update({
          'member_status': 'REMOVED',
          'is_inside_dindi': false,
          'removed_at': now,
          'removed_by': leaderUid,
        });

        await _firestore.collection('virtual_dindis').doc(dindiId).update({
          'active_member_count': FieldValue.increment(-1),
          'updated_at': now,
        });

        await logEvent(
          dindiId: dindiId,
          type: VirtualDindiEventType.MEMBER_LEFT,
          actorUid: leaderUid,
          targetUid: targetUid,
          details: '$targetName was removed by Dindi Leader.',
        );
      }
    }
  }

  /// Realtime Stream of Virtual Dindi Document.
  Stream<VirtualDindi?> streamDindi(String dindiId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore
        .collection('virtual_dindis')
        .doc(dindiId)
        .snapshots()
        .map((doc) => doc.exists ? VirtualDindi.fromJson(doc.data()!) : null);
  }

  /// Realtime Stream of Dindi Members.
  Stream<List<VirtualDindiMember>> streamMembers(String dindiId) {
    if (_firestore == null) return Stream.value([]);
    return _firestore
        .collection('virtual_dindis')
        .doc(dindiId)
        .collection('members')
        .where('member_status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VirtualDindiMember.fromJson(doc.data()))
            .toList());
  }

  /// Updates current user's location & separation state in Firestore.
  Future<void> updateMemberState({
    required String dindiId,
    required String uid,
    required double lat,
    required double lng,
    required double accuracy,
    required double distanceFromGroup,
    required SeparationState separationState,
    required MovementTrend trend,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();

    try {
      await _firestore
          .collection('virtual_dindis')
          .doc(dindiId)
          .collection('members')
          .doc(uid)
          .update({
        'last_latitude': lat,
        'last_longitude': lng,
        'accuracy_meters': accuracy,
        'last_location_at': now,
        'distance_from_group_meters': distanceFromGroup,
        'separation_state': separationState.name,
        'trend': trend.name,
        'is_inside_dindi': separationState == SeparationState.SAFE,
        'last_online_at': now,
      });
    } catch (e) {
      AppLogger.e('Failed to update Firestore member state (offline mode active)', e);
    }
  }

  /// Updates Dindi travel status (Leader control).
  Future<void> updateDindiStatus(String dindiId, VirtualDindiStatus status, String leaderUid) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('virtual_dindis').doc(dindiId).update({
      'status': status.name,
      'updated_at': now,
    });

    final VirtualDindiEventType eventType;
    switch (status) {
      case VirtualDindiStatus.ACTIVE: eventType = VirtualDindiEventType.DINDI_STARTED; break;
      case VirtualDindiStatus.PAUSED: eventType = VirtualDindiEventType.DINDI_PAUSED; break;
      case VirtualDindiStatus.ENDED:  eventType = VirtualDindiEventType.DINDI_ENDED; break;
    }

    await logEvent(
      dindiId: dindiId,
      type: eventType,
      actorUid: leaderUid,
      targetUid: leaderUid,
      details: 'Dindi status updated to ${status.name}',
    );
  }

  /// Updates Dindi meeting/reunification point (Leader control).
  Future<void> updateMeetingPoint({
    required String dindiId,
    required String leaderUid,
    required double lat,
    required double lng,
    required String name,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('virtual_dindis').doc(dindiId).update({
      'meeting_point_lat': lat,
      'meeting_point_lng': lng,
      'meeting_point_name': name,
      'updated_at': now,
    });

    await logEvent(
      dindiId: dindiId,
      type: VirtualDindiEventType.REUNIFICATION_STARTED,
      actorUid: leaderUid,
      targetUid: leaderUid,
      details: 'Reunification point updated to "$name"',
      latitude: lat,
      longitude: lng,
    );
  }

  /// Logs an audit event to `virtual_dindis/{dindiId}/events/{eventId}`.
  Future<void> logEvent({
    required String dindiId,
    required VirtualDindiEventType type,
    required String actorUid,
    required String targetUid,
    required String details,
    double? latitude,
    double? longitude,
    double? distanceMeters,
    bool createdOffline = false,
  }) async {
    final String eventId = _firestore != null
        ? _firestore.collection('virtual_dindis').doc(dindiId).collection('events').doc().id
        : 'evt_${DateTime.now().millisecondsSinceEpoch}';

    final event = VirtualDindiEvent(
      eventId: eventId,
      dindiId: dindiId,
      type: type,
      actorUid: actorUid,
      targetUid: targetUid,
      details: details,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters,
      timestamp: DateTime.now().toIso8601String(),
      createdOffline: createdOffline,
      syncedAt: createdOffline ? null : DateTime.now().toIso8601String(),
    );

    if (_firestore != null) {
      try {
        await _firestore.collection('virtual_dindis').doc(dindiId).collection('events').doc(eventId).set(event.toJson());
      } catch (_) {
        await VirtualDindiLocalService.queueOfflineEvent(event);
      }
    } else {
      await VirtualDindiLocalService.queueOfflineEvent(event);
    }
  }

  /// Synchronizes queued offline events with Cloud Firestore.
  Future<void> syncQueuedOfflineEvents() async {
    if (_firestore == null) return;
    final queued = await VirtualDindiLocalService.getQueuedOfflineEvents();
    if (queued.isEmpty) return;

    AppLogger.i('Synchronizing ${queued.length} queued offline Virtual Dindi events...');
    final now = DateTime.now().toIso8601String();

    for (final event in queued) {
      try {
        final docRef = _firestore
            .collection('virtual_dindis')
            .doc(event.dindiId)
            .collection('events')
            .doc(event.eventId);

        final doc = await docRef.get();
        if (!doc.exists) {
          final payload = event.toJson();
          payload['synced_at'] = now;
          await docRef.set(payload);
        }
      } catch (e) {
        AppLogger.e('Failed to sync offline event ${event.eventId}', e);
      }
    }

    await VirtualDindiLocalService.clearQueuedOfflineEvents();
    AppLogger.i('Queued offline Virtual Dindi events synchronized successfully.');
  }
}
