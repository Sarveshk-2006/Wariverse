import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_exports.dart';
import '../core/utils/volunteer_assignment_engine.dart';
import '../core/utils/app_logger.dart';

/// Firestore Repository for continuous Threat / Incident reporting and realtime response workflow.
class IncidentRepository {
  late final FirebaseFirestore? _firestore;

  IncidentRepository({FirebaseFirestore? firestore}) {
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

  /// Create a new Threat / Incident report in Cloud Firestore and auto-assign nearest volunteer.
  Future<ThreatIncident> createIncident({
    required String reporterUid,
    required String reporterName,
    required String reporterRole,
    String reporterPhone = '',
    required ThreatCategory category,
    required IncidentSeverity severity,
    required String description,
    required double latitude,
    required double longitude,
    double accuracyMeters = 10.0,
    List<String> mediaUrls = const [],
    String mediaType = 'NONE',
    bool isOffline = false,
  }) async {
    final String incidentId = _firestore != null
        ? _firestore.collection('incidents').doc().id
        : 'inc_${DateTime.now().millisecondsSinceEpoch}';

    final now = DateTime.now().toIso8601String();

    // 1. Fetch available volunteer candidates from Firestore users collection
    List<VolunteerCandidate> candidates = await _fetchVolunteerCandidates();

    // If Firestore users query returned empty, provide default operational responder candidates
    if (candidates.isEmpty) {
      candidates = _getDefaultVolunteerCandidates(latitude, longitude);
    }

    // 2. Select best volunteer using deterministic geospatial engine
    final assignment = VolunteerAssignmentEngine.selectBestVolunteer(
      category: category,
      incidentLat: latitude,
      incidentLng: longitude,
      candidates: candidates,
    );

    final selected = assignment.selectedVolunteer;
    final IncidentStatus initialStatus =
        selected != null ? IncidentStatus.ASSIGNED : IncidentStatus.ASSIGNING;

    final incident = ThreatIncident(
      incidentId: incidentId,
      reporterUid: reporterUid,
      reporterName: reporterName,
      reporterRole: reporterRole,
      reporterPhone: reporterPhone,
      category: category,
      severity: severity,
      description: description,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      locationTimestamp: now,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      status: initialStatus,
      priorityScore: assignment.score,
      assignedVolunteerUid: selected?.uid,
      assignedVolunteerName: selected?.displayName,
      assignedVolunteerPhone: selected?.phone,
      volunteerLatitude: selected?.latitude,
      volunteerLongitude: selected?.longitude,
      createdAt: now,
      updatedAt: now,
      assignedAt: selected != null ? now : null,
      isOffline: isOffline,
    );

    if (_firestore != null) {
      final docRef = _firestore.collection('incidents').doc(incidentId);
      await docRef.set(incident.toJson());

      // Log Creation & Assignment Events
      await logEvent(
        incidentId: incidentId,
        actorUid: reporterUid,
        action: 'INCIDENT_CREATED',
        details: 'Incident created: ${category.displayName} (${severity.displayName})',
        latitude: latitude,
        longitude: longitude,
      );

      if (selected != null) {
        await logEvent(
          incidentId: incidentId,
          actorUid: selected.uid,
          action: 'INCIDENT_ASSIGNED',
          details: 'Assigned to ${selected.displayName} (${assignment.rationale})',
          latitude: selected.latitude,
          longitude: selected.longitude,
        );
      }
    }

    AppLogger.i('Created Incident $incidentId (${category.name}) -> Assigned to ${selected?.displayName ?? "None"}');
    return incident;
  }

  /// Transactional Acceptance of assigned incident by Volunteer.
  /// Prevents two volunteers from accepting the same incident simultaneously.
  Future<ThreatIncident> acceptIncident({
    required String incidentId,
    required String volunteerUid,
    required String volunteerName,
  }) async {
    if (_firestore == null) {
      final now = DateTime.now().toIso8601String();
      return ThreatIncident(
        incidentId: incidentId,
        reporterUid: 'offline_reporter',
        reporterName: 'Varkari Pilgrim',
        reporterRole: 'VARKARI',
        category: ThreatCategory.MEDICAL_EMERGENCY,
        severity: IncidentSeverity.HIGH,
        description: 'Offline Incident',
        latitude: 18.5204,
        longitude: 73.8567,
        locationTimestamp: now,
        status: IncidentStatus.ACCEPTED,
        assignedVolunteerUid: volunteerUid,
        assignedVolunteerName: volunteerName,
        createdAt: now,
        updatedAt: now,
        acceptedAt: now,
      );
    }

    final docRef = _firestore.collection('incidents').doc(incidentId);

    return _firestore.runTransaction<ThreatIncident>((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Incident $incidentId does not exist.');
      }

      final data = snapshot.data()!;
      final currentAssignedUid = data['assigned_volunteer_uid'] as String?;
      final currentStatusStr = data['status'] as String? ?? '';

      // Verify that this volunteer is the assigned responder and status is ASSIGNED
      if (currentAssignedUid != null && currentAssignedUid != volunteerUid && currentStatusStr == 'ACCEPTED') {
        throw Exception('Incident already accepted by another responder.');
      }

      final now = DateTime.now().toIso8601String();
      final updatedData = Map<String, dynamic>.from(data);
      updatedData['status'] = IncidentStatus.ACCEPTED.name;
      updatedData['assigned_volunteer_uid'] = volunteerUid;
      updatedData['assigned_volunteer_name'] = volunteerName;
      updatedData['accepted_at'] = now;
      updatedData['updated_at'] = now;

      transaction.update(docRef, updatedData);
      return ThreatIncident.fromJson(updatedData);
    }).then((incident) async {
      await logEvent(
        incidentId: incidentId,
        actorUid: volunteerUid,
        action: 'INCIDENT_ACCEPTED',
        details: '$volunteerName accepted incident response.',
      );
      return incident;
    });
  }

  /// Sets incident status to EN_ROUTE.
  Future<void> setEnRoute({required String incidentId, required String volunteerUid}) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.EN_ROUTE.name,
      'enroute_at': now,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: volunteerUid,
      action: 'INCIDENT_EN_ROUTE',
      details: 'Responder is en route to Varkari location.',
    );
  }

  /// Marks incident status as ARRIVED.
  Future<void> markArrived({required String incidentId, required String volunteerUid}) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.ARRIVED.name,
      'arrived_at': now,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: volunteerUid,
      action: 'INCIDENT_ARRIVED',
      details: 'Responder arrived at Varkari location.',
    );
  }

  /// Resolves incident with notes.
  Future<void> resolveIncident({
    required String incidentId,
    required String volunteerUid,
    required String resolutionNotes,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.RESOLVED.name,
      'resolved_at': now,
      'resolution_notes': resolutionNotes,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: volunteerUid,
      action: 'INCIDENT_RESOLVED',
      details: 'Incident resolved: "$resolutionNotes"',
    );
  }

  /// Cancels incident (by Varkari reporter or Admin).
  Future<void> cancelIncident({required String incidentId, required String actorUid}) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.CANCELLED.name,
      'cancelled_at': now,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: actorUid,
      action: 'INCIDENT_CANCELLED',
      details: 'Incident cancelled by user.',
    );
  }

  /// Publishes Varkari's live GPS update to Firestore while incident is active.
  Future<void> updateReporterLocation({
    required String incidentId,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();

    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'latitude': lat,
        'longitude': lng,
        'accuracy_meters': accuracy,
        'location_timestamp': now,
        'updated_at': now,
      });

      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('reporter_locations')
          .add({
        'latitude': lat,
        'longitude': lng,
        'accuracy_meters': accuracy,
        'timestamp': now,
      });
    } catch (e) {
      AppLogger.e('Failed to update reporter location', e);
    }
  }

  /// Publishes Volunteer's live GPS update to Firestore while responding.
  Future<void> updateVolunteerLocation({
    required String incidentId,
    required String volunteerUid,
    required double lat,
    required double lng,
    required double accuracy,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();

    try {
      await _firestore.collection('incidents').doc(incidentId).update({
        'volunteer_latitude': lat,
        'volunteer_longitude': lng,
        'volunteer_accuracy_meters': accuracy,
        'volunteer_location_timestamp': now,
        'updated_at': now,
      });

      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('volunteer_locations')
          .add({
        'volunteer_uid': volunteerUid,
        'latitude': lat,
        'longitude': lng,
        'accuracy_meters': accuracy,
        'timestamp': now,
      });
    } catch (e) {
      AppLogger.e('Failed to update volunteer location', e);
    }
  }

  /// Realtime Stream of all active incidents (for Admin Command Center & Live Map).
  Stream<List<ThreatIncident>> streamAllIncidents() {
    if (_firestore == null) return Stream.value([]);
    return _firestore
        .collection('incidents')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ThreatIncident.fromJson(doc.data())).toList());
  }

  /// Realtime Stream of all operational incidents for Admin and NGO monitoring.
  Stream<List<ThreatIncident>> streamIncidents() {
    if (_firestore == null) return Stream.value([]);
    return _firestore
        .collection('incidents')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ThreatIncident.fromJson(doc.data())).toList());
  }

  /// One-time fetch of historical incidents from Cloud Firestore.
  Future<List<ThreatIncident>> getIncidents() async {
    if (_firestore == null) return [];
    try {
      final snap = await _firestore
          .collection('incidents')
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((doc) => ThreatIncident.fromJson(doc.data())).toList();
    } catch (e) {
      AppLogger.e('Failed to fetch incidents from Firestore', e);
      return [];
    }
  }

  /// Realtime Stream of incidents assigned to a specific Volunteer.
  Stream<List<ThreatIncident>> streamAssignedIncidents(String volunteerUid) {
    if (_firestore == null) return Stream.value([]);
    return _firestore
        .collection('incidents')
        .where('assigned_volunteer_uid', isEqualTo: volunteerUid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ThreatIncident.fromJson(doc.data())).toList());
  }

  /// Realtime Stream of active incidents reported by current Varkari.
  Stream<ThreatIncident?> streamMyActiveIncident(String reporterUid) {
    if (_firestore == null) return Stream.value(null);
    return _firestore
        .collection('incidents')
        .where('reporter_uid', isEqualTo: reporterUid)
        .snapshots()
        .map((snap) {
      final active = snap.docs
          .map((doc) => ThreatIncident.fromJson(doc.data()))
          .where((inc) => inc.isActive)
          .toList();
      return active.isNotEmpty ? active.first : null;
    });
  }

  /// Realtime Stream of single Incident document.
  Stream<ThreatIncident?> streamIncident(String incidentId) {
    if (_firestore == null) return Stream.value(null);
    return _firestore
        .collection('incidents')
        .doc(incidentId)
        .snapshots()
        .map((doc) => doc.exists ? ThreatIncident.fromJson(doc.data()!) : null);
  }

  /// Admin Intervention: Reassign Volunteer to an Incident.
  Future<void> reassignVolunteer({
    required String incidentId,
    required String newVolunteerUid,
    required String newVolunteerName,
    required String adminUid,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'assigned_volunteer_uid': newVolunteerUid,
      'assigned_volunteer_name': newVolunteerName,
      'status': IncidentStatus.ASSIGNED.name,
      'assigned_at': now,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: adminUid,
      action: 'ADMIN_REASSIGNED_VOLUNTEER',
      details: 'Reassigned to $newVolunteerName ($newVolunteerUid)',
    );

    await logAuditAction(
      actorUid: adminUid,
      action: 'ADMIN_REASSIGNED_VOLUNTEER',
      target: 'incidents/$incidentId',
      metadata: {'new_volunteer_uid': newVolunteerUid, 'new_volunteer_name': newVolunteerName},
    );
  }

  /// Admin Intervention: Escalate / Change Incident Priority & Severity.
  Future<void> changePriority({
    required String incidentId,
    required IncidentSeverity newSeverity,
    required String adminUid,
  }) async {
    if (_firestore == null) return;
    final now = DateTime.now().toIso8601String();
    await _firestore.collection('incidents').doc(incidentId).update({
      'severity': newSeverity.name,
      'updated_at': now,
    });

    await logEvent(
      incidentId: incidentId,
      actorUid: adminUid,
      action: 'ADMIN_CHANGED_PRIORITY',
      details: 'Severity changed to ${newSeverity.name}',
    );

    await logAuditAction(
      actorUid: adminUid,
      action: 'ADMIN_CHANGED_PRIORITY',
      target: 'incidents/$incidentId',
      metadata: {'new_severity': newSeverity.name},
    );
  }

  /// Write system audit log to audit_logs collection.
  Future<void> logAuditAction({
    required String actorUid,
    required String action,
    required String target,
    Map<String, dynamic>? metadata,
  }) async {
    if (_firestore == null) return;
    try {
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('audit_logs').doc(logId).set({
        'id': logId,
        'actor_uid': actorUid,
        'action': action,
        'target': target,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.i('Audit log notice: $e');
    }
  }

  /// Stream real-time audit logs from Firestore audit_logs collection.
  Stream<List<AuditLog>> streamAuditLogs() {
    if (_firestore == null) return Stream.value([]);
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AuditLog.fromJson(doc.data())).toList());
  }

  /// Logs audit event to `incidents/{incidentId}/events`.
  Future<void> logEvent({
    required String incidentId,
    required String actorUid,
    required String action,
    required String details,
    double? latitude,
    double? longitude,
  }) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('incidents')
          .doc(incidentId)
          .collection('events')
          .add({
        'incident_id': incidentId,
        'actor_uid': actorUid,
        'action': action,
        'details': details,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Helper to fetch candidates from Firestore users collection.
  Future<List<VolunteerCandidate>> _fetchVolunteerCandidates() async {
    if (_firestore == null) return [];
    try {
      final snap = await _firestore
          .collection('users')
          .get();

      final candidates = <VolunteerCandidate>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final roleStr = data['role'] as String? ?? 'VARKARI';
        final userRole = UserRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => UserRole.VARKARI,
        );

        if (userRole == UserRole.VOLUNTEER ||
            userRole == UserRole.MEDICAL_TEAM ||
            userRole == UserRole.POLICE ||
            userRole == UserRole.CLEANER ||
            userRole == UserRole.NGO) {
          candidates.add(VolunteerCandidate(
            uid: doc.id,
            displayName: data['name'] as String? ?? data['display_name'] as String? ?? 'Responder',
            role: userRole,
            phone: data['phone_number'] as String? ?? data['phone'] as String? ?? '',
            latitude: (data['latitude'] as num?)?.toDouble() ?? 18.5204,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 73.8567,
            isAvailable: true,
          ));
        }
      }
      return candidates;
    } catch (e) {
      return [];
    }
  }

  /// Default operational responder candidates for local / demo / test fallback.
  List<VolunteerCandidate> _getDefaultVolunteerCandidates(double refLat, double refLng) {
    return [
      VolunteerCandidate(
        uid: 'vol_med_01',
        displayName: 'Dr. Aarav Patel (Medical Team)',
        role: UserRole.MEDICAL_TEAM,
        phone: '+919822011111',
        latitude: refLat + 0.003,
        longitude: refLng + 0.002,
      ),
      VolunteerCandidate(
        uid: 'vol_sec_01',
        displayName: 'Inspector Vikram Singh (Police & Security)',
        role: UserRole.POLICE,
        phone: '+919822022222',
        latitude: refLat + 0.005,
        longitude: refLng - 0.003,
      ),
      VolunteerCandidate(
        uid: 'vol_gen_01',
        displayName: 'Rahul Deshmukh (Palkhi Volunteer)',
        role: UserRole.VOLUNTEER,
        phone: '+919822033333',
        latitude: refLat + 0.001,
        longitude: refLng + 0.001,
      ),
      VolunteerCandidate(
        uid: 'vol_san_01',
        displayName: 'Sanjay Shinde (Sanitation Team)',
        role: UserRole.CLEANER,
        phone: '+919822044444',
        latitude: refLat - 0.004,
        longitude: refLng + 0.002,
      ),
    ];
  }
}
