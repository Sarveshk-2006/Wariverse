// ignore_for_file: constant_identifier_names

/// Source of Dindi location update.
enum DindiLocationSource {
  LIVE,
  SIMULATED,
  OFFLINE,
}

extension DindiLocationSourceX on DindiLocationSource {
  String get displayName {
    switch (this) {
      case DindiLocationSource.LIVE:      return 'LIVE GPS';
      case DindiLocationSource.SIMULATED: return 'DEMO TRACKING';
      case DindiLocationSource.OFFLINE:   return 'OFFLINE';
    }
  }
}

/// Dynamic movement status of a Dindi procession unit.
enum DindiMovementStatus {
  MOVING,
  AT_HALT,
  APPROACHING_HALT,
  OFFLINE,
}

extension DindiMovementStatusX on DindiMovementStatus {
  String get displayName {
    switch (this) {
      case DindiMovementStatus.MOVING:           return 'MOVING (प्रवास सुरू)';
      case DindiMovementStatus.AT_HALT:          return 'AT HALT (थांब्यावर मुक्काम)';
      case DindiMovementStatus.APPROACHING_HALT: return 'APPROACHING HALT (थांब्याजवळ)';
      case DindiMovementStatus.OFFLINE:          return 'OFFLINE (ऑफलाइन)';
    }
  }
}

/// Represents a single spatial location update for a Dindi unit along the route.
class DindiLocationUpdate {
  final String dindiId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final DindiLocationSource source;
  final DindiMovementStatus status;
  final double speedKmh;
  final double heading;
  final String nextHaltName;
  final double distanceToNextHaltKm;
  final int etaNextHaltMinutes;
  final double progressPercentage;

  const DindiLocationUpdate({
    required this.dindiId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    required this.status,
    this.speedKmh = 4.5,
    this.heading = 135.0,
    required this.nextHaltName,
    required this.distanceToNextHaltKm,
    required this.etaNextHaltMinutes,
    required this.progressPercentage,
  });

  bool get isSimulated => source == DindiLocationSource.SIMULATED;
  bool get isLive => source == DindiLocationSource.LIVE;
  bool get isOffline => source == DindiLocationSource.OFFLINE;

  factory DindiLocationUpdate.fromJson(Map<String, dynamic> json) => DindiLocationUpdate(
        dindiId: json['dindi_id'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        source: DindiLocationSource.values.firstWhere(
          (e) => e.name == (json['source'] as String? ?? 'SIMULATED'),
          orElse: () => DindiLocationSource.SIMULATED,
        ),
        status: DindiMovementStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'MOVING'),
          orElse: () => DindiMovementStatus.MOVING,
        ),
        speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 4.5,
        heading: (json['heading'] as num?)?.toDouble() ?? 135.0,
        nextHaltName: json['next_halt_name'] as String? ?? 'Next Halt',
        distanceToNextHaltKm: (json['distance_to_next_halt_km'] as num?)?.toDouble() ?? 0.0,
        etaNextHaltMinutes: json['eta_next_halt_minutes'] as int? ?? 0,
        progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'dindi_id': dindiId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'source': source.name,
        'status': status.name,
        'speed_kmh': speedKmh,
        'heading': heading,
        'next_halt_name': nextHaltName,
        'distance_to_next_halt_km': distanceToNextHaltKm,
        'eta_next_halt_minutes': etaNextHaltMinutes,
        'progress_percentage': progressPercentage,
      };
}
