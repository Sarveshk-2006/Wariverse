import 'package:intl/intl.dart';

/// Comprehensive Offline Snapshot model containing full Wari route data and service layers.
class OfflineMapSnapshot {
  final String snapshotId;
  final String routeId;
  final String routeName;
  final String downloadedAt;
  final String? expiresAt;
  final double centerLatitude;
  final double centerLongitude;
  final Map<String, double>? currentUserLocation;
  final List<Map<String, double>> routePolyline;
  final List<Map<String, dynamic>> foodCentres;
  final List<Map<String, dynamic>> waterPoints;
  final List<Map<String, dynamic>> shelters;
  final List<Map<String, dynamic>> medicalLocations;
  final List<Map<String, dynamic>> toilets;
  final List<Map<String, dynamic>> wellnessCentres;
  final List<Map<String, dynamic>> crowdZones;
  final List<Map<String, dynamic>> crowdAlerts;
  final List<Map<String, dynamic>> dindiLocations;
  final List<Map<String, dynamic>> resourceDistributions;
  final Map<String, dynamic> mapMetadata;

  OfflineMapSnapshot({
    required this.snapshotId,
    required this.routeId,
    required this.routeName,
    required this.downloadedAt,
    this.expiresAt,
    required this.centerLatitude,
    required this.centerLongitude,
    this.currentUserLocation,
    required this.routePolyline,
    required this.foodCentres,
    required this.waterPoints,
    required this.shelters,
    required this.medicalLocations,
    required this.toilets,
    required this.wellnessCentres,
    required this.crowdZones,
    required this.crowdAlerts,
    required this.dindiLocations,
    required this.resourceDistributions,
    required this.mapMetadata,
  });

  /// Calculate total count of downloaded map elements.
  int get totalElementCount {
    return foodCentres.length +
        waterPoints.length +
        shelters.length +
        medicalLocations.length +
        toilets.length +
        wellnessCentres.length +
        crowdZones.length +
        dindiLocations.length +
        resourceDistributions.length;
  }

  /// Formatted date string for UI display.
  String get formattedDownloadedAt {
    try {
      final dt = DateTime.parse(downloadedAt);
      return DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {
      return downloadedAt;
    }
  }

  /// Relative age string (e.g. "18 minutes ago").
  String get relativeAgeString {
    try {
      final dt = DateTime.parse(downloadedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hrs ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  /// Estimated snapshot payload size in MB.
  double get estimatedSizeMb {
    final bytes = (mapMetadata['estimated_size_bytes'] as num?)?.toDouble() ??
        (totalElementCount * 850.0 + routePolyline.length * 50.0);
    return bytes / (1024.0 * 1024.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshot_id': snapshotId,
      'route_id': routeId,
      'route_name': routeName,
      'downloaded_at': downloadedAt,
      'expires_at': expiresAt,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'current_user_location': currentUserLocation,
      'route_polyline': routePolyline,
      'food_centres': foodCentres,
      'water_points': waterPoints,
      'shelters': shelters,
      'medical_locations': medicalLocations,
      'toilets': toilets,
      'wellness_centres': wellnessCentres,
      'crowd_zones': crowdZones,
      'crowd_alerts': crowdAlerts,
      'dindi_locations': dindiLocations,
      'resource_distributions': resourceDistributions,
      'map_metadata': mapMetadata,
    };
  }

  factory OfflineMapSnapshot.fromJson(Map<String, dynamic> json) {
    List<Map<String, double>> parsePolyline(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((item) {
        if (item is Map) {
          return {
            'latitude': (item['latitude'] as num).toDouble(),
            'longitude': (item['longitude'] as num).toDouble(),
          };
        }
        return {'latitude': 0.0, 'longitude': 0.0};
      }).toList();
    }

    List<Map<String, dynamic>> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return OfflineMapSnapshot(
      snapshotId: json['snapshot_id'] ?? 'snapshot_default',
      routeId: json['route_id'] ?? 'alandi_pandharpur',
      routeName: json['route_name'] ?? 'Alandi → Pandharpur Wari Route',
      downloadedAt: json['downloaded_at'] ?? DateTime.now().toIso8601String(),
      expiresAt: json['expires_at'],
      centerLatitude: (json['center_latitude'] as num?)?.toDouble() ?? 18.5204,
      centerLongitude: (json['center_longitude'] as num?)?.toDouble() ?? 73.8567,
      currentUserLocation: json['current_user_location'] != null
          ? Map<String, double>.from(
              (json['current_user_location'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null,
      routePolyline: parsePolyline(json['route_polyline']),
      foodCentres: parseList(json['food_centres']),
      waterPoints: parseList(json['water_points']),
      shelters: parseList(json['shelters']),
      medicalLocations: parseList(json['medical_locations']),
      toilets: parseList(json['toilets']),
      wellnessCentres: parseList(json['wellness_centres']),
      crowdZones: parseList(json['crowd_zones']),
      crowdAlerts: parseList(json['crowd_alerts']),
      dindiLocations: parseList(json['dindi_locations']),
      resourceDistributions: parseList(json['resource_distributions']),
      mapMetadata: json['map_metadata'] != null
          ? Map<String, dynamic>.from(json['map_metadata'])
          : {},
    );
  }
}
