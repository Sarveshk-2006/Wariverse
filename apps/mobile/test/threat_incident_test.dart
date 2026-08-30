import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/core/utils/volunteer_assignment_engine.dart';
import 'package:mobile/repositories/incident_repository.dart';

void main() {
  group('ThreatIncident Model Tests', () {
    test('Serializes and deserializes ThreatIncident JSON correctly', () {
      final incident = ThreatIncident(
        incidentId: 'inc_test_100',
        reporterUid: 'user_varkari_01',
        reporterName: 'Sunita Patil',
        reporterRole: 'VARKARI',
        category: ThreatCategory.MEDICAL_EMERGENCY,
        severity: IncidentSeverity.CRITICAL,
        description: 'Pilgrim collapsed near Pandharpur temple stage.',
        latitude: 17.6775,
        longitude: 75.3283,
        accuracyMeters: 5.0,
        locationTimestamp: '2026-08-30T00:00:00Z',
        status: IncidentStatus.ASSIGNED,
        assignedVolunteerUid: 'vol_doctor_01',
        assignedVolunteerName: 'Dr. Ramesh',
        createdAt: '2026-08-30T00:00:00Z',
        updatedAt: '2026-08-30T00:00:00Z',
      );

      final json = incident.toJson();
      expect(json['incident_id'], equals('inc_test_100'));
      expect(json['category'], equals('MEDICAL_EMERGENCY'));
      expect(json['severity'], equals('CRITICAL'));
      expect(json['status'], equals('ASSIGNED'));

      final parsed = ThreatIncident.fromJson(json);
      expect(parsed.incidentId, equals('inc_test_100'));
      expect(parsed.category, equals(ThreatCategory.MEDICAL_EMERGENCY));
      expect(parsed.severity, equals(IncidentSeverity.CRITICAL));
      expect(parsed.status, equals(IncidentStatus.ASSIGNED));
      expect(parsed.assignedVolunteerUid, equals('vol_doctor_01'));
      expect(parsed.isActive, isTrue);
    });

    test('Resolved incident reports isActive = false', () {
      final incident = ThreatIncident(
        incidentId: 'inc_done',
        reporterUid: 'user_1',
        reporterName: 'Test',
        reporterRole: 'VARKARI',
        category: ThreatCategory.OTHER,
        severity: IncidentSeverity.LOW,
        description: 'Resolved',
        latitude: 18.5204,
        longitude: 73.8567,
        locationTimestamp: '2026-08-30T00:00:00Z',
        status: IncidentStatus.RESOLVED,
        createdAt: '2026-08-30T00:00:00Z',
        updatedAt: '2026-08-30T00:00:00Z',
      );

      expect(incident.isActive, isFalse);
    });

    test('Robustly handles malformed timestamps, null values, and missing GPS without crash', () {
      final malformedMap = <String, dynamic>{
        'id': 'inc_malformed_001',
        'latitude': null,
        'longitude': 0.0,
        'created_at': 1788050000000,
        'resolved_at': null,
        'category': 'INVALID_CATEGORY',
        'status': 'UNKNOWN_STATUS',
      };

      final parsed = ThreatIncident.fromJson(malformedMap);
      expect(parsed.incidentId, equals('inc_malformed_001'));
      expect(parsed.latitude, equals(18.5204));
      expect(parsed.longitude, equals(73.8567));
      expect(parsed.category, equals(ThreatCategory.OTHER));
      expect(parsed.status, equals(IncidentStatus.CREATED));

      final parsedSos = SOSIncident.fromJson(malformedMap);
      expect(parsedSos.id, equals('inc_malformed_001'));
      expect(parsedSos.latitude, equals(18.5204));
      expect(parsedSos.longitude, equals(73.8567));
    });
  });

  group('VolunteerAssignmentEngine Tests', () {
    test('Calculates Haversine distance correctly', () {
      // Pandharpur (17.6775, 75.3283) to Pune (18.5204, 73.8567) is ~210 km
      final distMeters = VolunteerAssignmentEngine.haversineDistanceMeters(
        17.6775, 75.3283,
        18.5204, 73.8567,
      );
      expect(distMeters, greaterThan(170000.0));
      expect(distMeters, lessThan(195000.0));
    });

    test('Prioritizes Medical Team role for Medical Emergency', () {
      final candidates = [
        const VolunteerCandidate(
          uid: 'vol_gen',
          displayName: 'General Volunteer',
          role: UserRole.VOLUNTEER,
          latitude: 17.6780,
          longitude: 75.3285,
        ),
        const VolunteerCandidate(
          uid: 'vol_med',
          displayName: 'Doctor Responder',
          role: UserRole.MEDICAL_TEAM,
          latitude: 17.6780,
          longitude: 75.3285,
        ),
      ];

      final result = VolunteerAssignmentEngine.selectBestVolunteer(
        category: ThreatCategory.MEDICAL_EMERGENCY,
        incidentLat: 17.6775,
        incidentLng: 75.3283,
        candidates: candidates,
      );

      expect(result.selectedVolunteer, isNotNull);
      expect(result.selectedVolunteer!.uid, equals('vol_med'));
      expect(result.selectedVolunteer!.role, equals(UserRole.MEDICAL_TEAM));
    });

    test('Prioritizes nearest candidate when capabilities match', () {
      final candidates = [
        const VolunteerCandidate(
          uid: 'vol_far',
          displayName: 'Far Doctor',
          role: UserRole.MEDICAL_TEAM,
          latitude: 17.7500, // ~8 km away
          longitude: 75.3283,
        ),
        const VolunteerCandidate(
          uid: 'vol_near',
          displayName: 'Near Doctor',
          role: UserRole.MEDICAL_TEAM,
          latitude: 17.6780, // ~60 meters away
          longitude: 75.3283,
        ),
      ];

      final result = VolunteerAssignmentEngine.selectBestVolunteer(
        category: ThreatCategory.ACCIDENT,
        incidentLat: 17.6775,
        incidentLng: 75.3283,
        candidates: candidates,
      );

      expect(result.selectedVolunteer!.uid, equals('vol_near'));
    });
  });

  group('IncidentRepository Tests', () {
    test('Creates incident and assigns candidate offline fallback', () async {
      final repo = IncidentRepository();
      final incident = await repo.createIncident(
        reporterUid: 'test_varkari_99',
        reporterName: 'Anil Kumar',
        reporterRole: 'VARKARI',
        category: ThreatCategory.STAMPEDE_RISK,
        severity: IncidentSeverity.CRITICAL,
        description: 'Heavy crowd bottleneck near gate #3',
        latitude: 17.6775,
        longitude: 75.3283,
      );

      expect(incident.incidentId, isNotEmpty);
      expect(incident.category, equals(ThreatCategory.STAMPEDE_RISK));
      expect(incident.severity, equals(IncidentSeverity.CRITICAL));
      expect(incident.assignedVolunteerUid, isNotNull);
      expect(incident.status, equals(IncidentStatus.ASSIGNED));
    });
  });
}
