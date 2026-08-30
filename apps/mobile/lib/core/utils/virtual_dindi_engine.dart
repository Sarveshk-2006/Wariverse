import 'dart:math' as math;
import '../../models/virtual_dindi_model.dart';

/// Group Center Calculation Result.
class GroupCenterResult {
  final double latitude;
  final double longitude;
  final int activeContributingMembers;
  final bool isReliable;

  const GroupCenterResult({
    required this.latitude,
    required this.longitude,
    required this.activeContributingMembers,
    required this.isReliable,
  });
}

/// Member Separation Evaluation Result.
class MemberSeparationEvaluation {
  final double rawDistanceMeters;
  final double effectiveDistanceMeters;
  final SeparationState separationState;
  final MovementTrend trend;
  final bool stateChanged;

  const MemberSeparationEvaluation({
    required this.rawDistanceMeters,
    required this.effectiveDistanceMeters,
    required this.separationState,
    required this.trend,
    required this.stateChanged,
  });
}

/// Deterministic Geospatial Engine for Virtual Dindi Separation & Group Analysis.
class VirtualDindiEngine {
  /// Validates standard GPS latitude and longitude parameters.
  static bool isValidCoordinate(double lat, double lng) {
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) return false;
    if (lat.abs() > 90.0 || lng.abs() > 180.0) return false;
    return true;
  }

  /// Computes Haversine distance between two sets of GPS coordinates in meters.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) {
      return 0.0;
    }
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    const double R = 6371000.0; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
    return R * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Format distance into clean human readable string (e.g., "42 m away", "1.4 km away").
  static String formatDistance(double meters) {
    if (meters < 0) return '0 m away';
    if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      return '${(meters / 1000.0).toStringAsFixed(1)} km away';
    }
  }

  /// Calculates robust group center of active Dindi members.
  /// Filters out:
  /// 1. Invalid coordinates.
  /// 2. Stale locations (> 10 minutes old).
  /// 3. Low-accuracy GPS fixes (> 150m accuracy).
  /// 4. Inactive/left members.
  static GroupCenterResult calculateRobustGroupCenter(
    List<VirtualDindiMember> members, {
    double fallbackLat = 18.5204,
    double fallbackLng = 73.8567,
    int maxStaleMinutes = 15,
    double maxAccuracyMeters = 150.0,
  }) {
    final now = DateTime.now();

    final validMembers = members.where((m) {
      if (m.memberStatus != 'ACTIVE') return false;
      if (!isValidCoordinate(m.lastLatitude, m.lastLongitude)) return false;
      if (m.accuracyMeters > maxAccuracyMeters) return false;

      final locTime = DateTime.tryParse(m.lastLocationAt);
      if (locTime != null && now.difference(locTime).inMinutes > maxStaleMinutes) {
        return false;
      }

      return true;
    }).toList();

    if (validMembers.isEmpty) {
      // If no valid member locations pass accuracy filter, use any member with valid coordinates (preferably Leader)
      final leader = members.firstWhere(
        (m) => m.isLeader && isValidCoordinate(m.lastLatitude, m.lastLongitude),
        orElse: () => members.firstWhere(
          (m) => isValidCoordinate(m.lastLatitude, m.lastLongitude),
          orElse: () => VirtualDindiMember(
            uid: 'fallback',
            displayName: 'Fallback',
            joinedAt: now.toIso8601String(),
            lastLatitude: fallbackLat,
            lastLongitude: fallbackLng,
            lastLocationAt: now.toIso8601String(),
            lastOnlineAt: now.toIso8601String(),
          ),
        ),
      );

      return GroupCenterResult(
        latitude: leader.lastLatitude,
        longitude: leader.lastLongitude,
        activeContributingMembers: 0,
        isReliable: false,
      );
    }

    // Sort latitudes and longitudes to compute geographic median
    final lats = validMembers.map((m) => m.lastLatitude).toList()..sort();
    final lngs = validMembers.map((m) => m.lastLongitude).toList()..sort();

    final int midIndex = lats.length ~/ 2;
    double medianLat = lats.length.isOdd
        ? lats[midIndex]
        : (lats[midIndex - 1] + lats[midIndex]) / 2.0;

    double medianLng = lngs.length.isOdd
        ? lngs[midIndex]
        : (lngs[midIndex - 1] + lngs[midIndex]) / 2.0;

    return GroupCenterResult(
      latitude: medianLat,
      longitude: medianLng,
      activeContributingMembers: validMembers.length,
      isReliable: true,
    );
  }

  /// Evaluates member separation state incorporating GPS accuracy, hysteresis, and movement trend.
  static MemberSeparationEvaluation evaluateMemberSeparation({
    required double memberLat,
    required double memberLng,
    required double accuracyMeters,
    required double groupCenterLat,
    required double groupCenterLng,
    required SeparationState currentPreviousState,
    required DateTime stateEnteredAt,
    required double previousDistanceMeters,
    double safeRadius = 75.0,
    double cautionThreshold = 150.0,
    double criticalThreshold = 300.0,
  }) {
    final double rawDistance = haversineDistance(
      memberLat,
      memberLng,
      groupCenterLat,
      groupCenterLng,
    );

    // Incorporate GPS accuracy into effective distance confidence interval.
    final double effectiveDistance = math.max(0.0, rawDistance - (accuracyMeters / 2.0));

    // Determine Movement Trend (delta vs previous distance sample)
    final double deltaDistance = rawDistance - previousDistanceMeters;
    final MovementTrend trend;
    if (deltaDistance > 5.0) {
      trend = MovementTrend.MOVING_AWAY;
    } else if (deltaDistance < -5.0) {
      trend = MovementTrend.RETURNING;
    } else {
      trend = MovementTrend.STABLE_SEPARATION;
    }

    final now = DateTime.now();
    final int secondsInCurrentState = now.difference(stateEnteredAt).inSeconds;

    SeparationState targetState = currentPreviousState;

    // Hysteresis & Persistence Rules
    if (effectiveDistance <= safeRadius) {
      // Recovery logic: Require stabilization period inside safe radius if previously separated
      if (currentPreviousState == SeparationState.SAFE) {
        targetState = SeparationState.SAFE;
      } else if (currentPreviousState == SeparationState.RETURNING || currentPreviousState == SeparationState.CAUTION) {
        if (secondsInCurrentState >= 10 || trend == MovementTrend.RETURNING) {
          targetState = SeparationState.SAFE;
        } else {
          targetState = SeparationState.RETURNING;
        }
      } else {
        // If coming from SEPARATED or CRITICAL, step down to RETURNING first
        targetState = SeparationState.RETURNING;
      }
    } else if (effectiveDistance > safeRadius && effectiveDistance <= cautionThreshold) {
      // CAUTION: Must exceed 75m for at least 20s or be moving away
      if (currentPreviousState == SeparationState.SAFE) {
        targetState = SeparationState.CAUTION;
      } else if (currentPreviousState == SeparationState.SEPARATED || currentPreviousState == SeparationState.CRITICAL) {
        targetState = SeparationState.RETURNING;
      } else {
        targetState = SeparationState.CAUTION;
      }
    } else if (effectiveDistance > cautionThreshold && effectiveDistance <= criticalThreshold) {
      // SEPARATED: Exceeds 150m
      if (currentPreviousState == SeparationState.CRITICAL) {
        targetState = SeparationState.RETURNING;
      } else if (currentPreviousState == SeparationState.CAUTION || secondsInCurrentState >= 30) {
        targetState = SeparationState.SEPARATED;
      } else {
        targetState = SeparationState.CAUTION;
      }
    } else {
      // CRITICAL: Exceeds 300m
      if (currentPreviousState == SeparationState.SEPARATED && secondsInCurrentState >= 30) {
        targetState = SeparationState.CRITICAL;
      } else if (trend == MovementTrend.MOVING_AWAY) {
        targetState = SeparationState.CRITICAL;
      } else {
        targetState = SeparationState.SEPARATED;
      }
    }

    return MemberSeparationEvaluation(
      rawDistanceMeters: rawDistance,
      effectiveDistanceMeters: effectiveDistance,
      separationState: targetState,
      trend: trend,
      stateChanged: targetState != currentPreviousState,
    );
  }
}
