// ignore_for_file: constant_identifier_names
import 'package:latlong2/latlong.dart';

/// Crowd level enum matching backend CrowdLevel enum.
enum CrowdLevel { GREEN, YELLOW, ORANGE, RED }

extension CrowdLevelX on CrowdLevel {
  String get label {
    switch (this) {
      case CrowdLevel.GREEN:  return 'Safe';
      case CrowdLevel.YELLOW: return 'Moderate';
      case CrowdLevel.ORANGE: return 'High';
      case CrowdLevel.RED:    return 'Critical';
    }
  }

  static CrowdLevel fromString(String s) {
    return CrowdLevel.values.firstWhere(
      (e) => e.name == s.toUpperCase(),
      orElse: () => CrowdLevel.GREEN,
    );
  }
}

/// Represents a crowd monitoring zone returned from /crowd/current.
class CrowdZone {
  final String id;
  final String name;
  final CrowdLevel crowdLevel;
  final double currentDensity;
  final int estimatedCount;
  final double latitude;
  final double longitude;
  final double radiusM;
  final String? zoneType;

  const CrowdZone({
    required this.id,
    required this.name,
    required this.crowdLevel,
    required this.currentDensity,
    required this.estimatedCount,
    required this.latitude,
    required this.longitude,
    this.radiusM = 500.0,
    this.zoneType,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory CrowdZone.fromJson(Map<String, dynamic> json) => CrowdZone(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        crowdLevel: CrowdLevelX.fromString(json['crowd_level'] as String? ?? 'GREEN'),
        currentDensity: (json['current_density'] as num?)?.toDouble() ?? 0.0,
        estimatedCount: json['estimated_count'] as int? ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 17.6741,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 75.3279,
        radiusM: (json['radius_m'] as num?)?.toDouble() ?? 500.0,
        zoneType: json['zone_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'crowd_level': crowdLevel.name,
        'current_density': currentDensity,
        'estimated_count': estimatedCount,
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': radiusM,
        'zone_type': zoneType,
      };
}

/// AI-powered crowd prediction for a zone.
class ZonePrediction {
  final String zoneId;
  final String zoneName;
  final double currentDensity;
  final double predictedDensity30min;
  final String riskLevel;
  final String recommendation;

  const ZonePrediction({
    required this.zoneId,
    required this.zoneName,
    required this.currentDensity,
    required this.predictedDensity30min,
    required this.riskLevel,
    required this.recommendation,
  });

  factory ZonePrediction.fromJson(Map<String, dynamic> json) => ZonePrediction(
        zoneId: json['zone_id'] as String? ?? '',
        zoneName: json['zone_name'] as String? ?? '',
        currentDensity: (json['current_density'] as num?)?.toDouble() ?? 0.0,
        predictedDensity30min:
            (json['predicted_density_30min'] as num?)?.toDouble() ?? 0.0,
        riskLevel: json['risk_level'] as String? ?? 'LOW',
        recommendation: json['recommendation'] as String? ?? '',
      );
}

/// Container for the /crowd/prediction response.
class CrowdPrediction {
  final List<ZonePrediction> predictions;

  const CrowdPrediction({required this.predictions});

  factory CrowdPrediction.fromJson(Map<String, dynamic> json) => CrowdPrediction(
        predictions: (json['predictions'] as List<dynamic>? ?? [])
            .map((e) => ZonePrediction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
