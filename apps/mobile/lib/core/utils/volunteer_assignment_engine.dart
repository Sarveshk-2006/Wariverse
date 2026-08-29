import 'dart:math';
import '../../models/models_exports.dart';

class VolunteerCandidate {
  final String uid;
  final String displayName;
  final UserRole role;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final int activeAssignedIncidentsCount;

  const VolunteerCandidate({
    required this.uid,
    required this.displayName,
    required this.role,
    this.phone = '',
    required this.latitude,
    required this.longitude,
    this.isAvailable = true,
    this.activeAssignedIncidentsCount = 0,
  });
}

class VolunteerAssignmentResult {
  final VolunteerCandidate? selectedVolunteer;
  final double score;
  final double distanceMeters;
  final String rationale;

  const VolunteerAssignmentResult({
    this.selectedVolunteer,
    this.score = 0.0,
    this.distanceMeters = 0.0,
    required this.rationale,
  });
}

/// Deterministic Geospatial Volunteer Assignment Engine.
/// Ranks available responders based on capability match, Haversine distance, and current workload.
class VolunteerAssignmentEngine {

  /// Calculate Haversine distance in meters between two GPS coordinates.
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Calculates capability match score between incident category and candidate role.
  static double calculateCapabilityWeight(ThreatCategory category, UserRole role) {
    switch (category) {
      case ThreatCategory.MEDICAL_EMERGENCY:
      case ThreatCategory.ACCIDENT:
        if (role == UserRole.MEDICAL_TEAM) return 100.0;
        if (role == UserRole.VOLUNTEER) return 60.0;
        return 40.0;

      case ThreatCategory.SECURITY_THREAT:
      case ThreatCategory.HARASSMENT:
      case ThreatCategory.SUSPICIOUS_ACTIVITY:
      case ThreatCategory.CROWD_DANGER:
      case ThreatCategory.STAMPEDE_RISK:
        if (role == UserRole.POLICE) return 100.0;
        if (role == UserRole.VOLUNTEER) return 60.0;
        return 40.0;

      case ThreatCategory.SANITATION_PROBLEM:
      case ThreatCategory.WATER_EMERGENCY:
        if (role == UserRole.CLEANER) return 100.0;
        if (role == UserRole.VOLUNTEER) return 60.0;
        return 40.0;

      case ThreatCategory.FOOD_PROBLEM:
      case ThreatCategory.INFRASTRUCTURE_DAMAGE:
      case ThreatCategory.ROAD_BLOCKAGE:
        if (role == UserRole.NGO) return 90.0;
        if (role == UserRole.VOLUNTEER) return 75.0;
        return 50.0;

      default:
        if (role == UserRole.VOLUNTEER) return 80.0;
        if (role == UserRole.POLICE || role == UserRole.MEDICAL_TEAM) return 70.0;
        return 50.0;
    }
  }

  /// Selects the best candidate volunteer using deterministic scoring:
  /// assignmentScore = capabilityMatchWeight + availabilityWeight - (distanceKm * 10) - (workload * 25)
  static VolunteerAssignmentResult selectBestVolunteer({
    required ThreatCategory category,
    required double incidentLat,
    required double incidentLng,
    required List<VolunteerCandidate> candidates,
    double maxDistanceMeters = 20000.0, // 20 km search radius
  }) {
    if (candidates.isEmpty) {
      return const VolunteerAssignmentResult(
        rationale: 'No volunteer candidates registered in system.',
      );
    }

    VolunteerCandidate? bestCandidate;
    double highestScore = -999999.0;
    double bestDistance = 0.0;

    for (final candidate in candidates) {
      if (!candidate.isAvailable) continue;

      final distMeters = haversineDistanceMeters(
        incidentLat,
        incidentLng,
        candidate.latitude,
        candidate.longitude,
      );

      if (distMeters > maxDistanceMeters) continue;

      final distKm = distMeters / 1000.0;
      final capabilityWeight = calculateCapabilityWeight(category, candidate.role);
      const availabilityWeight = 50.0;
      final distancePenalty = distKm * 10.0;
      final workloadPenalty = candidate.activeAssignedIncidentsCount * 25.0;

      final score = capabilityWeight + availabilityWeight - distancePenalty - workloadPenalty;

      if (score > highestScore) {
        highestScore = score;
        bestCandidate = candidate;
        bestDistance = distMeters;
      }
    }

    if (bestCandidate == null) {
      return const VolunteerAssignmentResult(
        rationale: 'No available volunteers found within maximum response radius.',
      );
    }

    return VolunteerAssignmentResult(
      selectedVolunteer: bestCandidate,
      score: highestScore,
      distanceMeters: bestDistance,
      rationale:
          'Selected ${bestCandidate.displayName} (${bestCandidate.role.name}) at distance ${bestDistance.toInt()}m with score ${highestScore.toStringAsFixed(1)}.',
    );
  }
}
