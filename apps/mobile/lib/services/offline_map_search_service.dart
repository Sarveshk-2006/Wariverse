import 'package:geolocator/geolocator.dart';
import '../models/offline_map_snapshot.dart';

/// Search Result object derived strictly from local offline snapshot data.
class OfflineSearchResult {
  final String id;
  final String title;
  final String category; // 'FOOD', 'WATER', 'MEDICAL', 'TOILET', 'SHELTER', 'WELLNESS', 'CROWD', 'DINDI', 'DISTRIBUTION'
  final String subtitle;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final String statusInfo;
  final String snapshotTimestamp;
  final Map<String, dynamic> rawData;

  OfflineSearchResult({
    required this.id,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    required this.statusInfo,
    required this.snapshotTimestamp,
    required this.rawData,
  });
}

/// Offline Search Service for querying downloaded map snapshots without network connectivity.
class OfflineMapSearchService {
  /// Search across all categories in an OfflineMapSnapshot.
  static List<OfflineSearchResult> searchOffline(
    OfflineMapSnapshot snapshot,
    String query, {
    double? userLat,
    double? userLon,
  }) {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final List<OfflineSearchResult> results = [];

    double? calcDistance(double lat, double lon) {
      if (userLat == null || userLon == null) return null;
      try {
        final meters = Geolocator.distanceBetween(userLat, userLon, lat, lon);
        return meters / 1000.0;
      } catch (_) {
        return null;
      }
    }

    // Helper matcher
    bool matches(String? name, String? desc, String categoryName) {
      final n = (name ?? '').toLowerCase();
      final d = (desc ?? '').toLowerCase();
      final c = categoryName.toLowerCase();
      return n.contains(q) || d.contains(q) || c.contains(q) || q.contains(c);
    }

    // 1. Food Centres
    for (final item in snapshot.foodCentres) {
      final name = item['name'] as String? ?? 'Food Centre';
      final desc = item['operating_hours'] as String? ?? 'Free Annadan';
      if (matches(name, desc, 'food') || q.contains('annadan') || q.contains('khichdi')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'food_${results.length}',
          title: name,
          category: 'FOOD',
          subtitle: 'Food · ${item['is_available'] == true ? 'Available' : 'Limited'}',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: 'Wait time ~${item['wait_time_mins'] ?? 10} mins',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 2. Water Points
    for (final item in snapshot.waterPoints) {
      final name = item['name'] as String? ?? 'Water Point';
      final desc = item['location_name'] as String? ?? 'Clean Drinking Water';
      if (matches(name, desc, 'water') || q.contains('pani') || q.contains('drink')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'water_${results.length}',
          title: name,
          category: 'WATER',
          subtitle: 'Water · Clean Drinking Water',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: item['is_functional'] == false ? 'Under Maintenance' : 'Functional',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 3. Medical Locations
    for (final item in snapshot.medicalLocations) {
      final name = item['name'] as String? ?? 'Medical Centre';
      final desc = item['address'] as String? ?? 'Emergency Aid';
      if (matches(name, desc, 'medical') || q.contains('doctor') || q.contains('hospital') || q.contains('ambulance')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'med_${results.length}',
          title: name,
          category: 'MEDICAL',
          subtitle: 'Medical · Doctors & First Aid',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: item['ambulance_available'] == true ? 'Ambulance On-Site' : 'First Aid Active',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 4. Toilets
    for (final item in snapshot.toilets) {
      final name = item['name'] as String? ?? 'Mobile Toilet Block';
      final desc = item['type'] as String? ?? 'Sanitation Facility';
      if (matches(name, desc, 'toilet') || q.contains('sanitation') || q.contains('washroom') || q.contains('wc')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'toilet_${results.length}',
          title: name,
          category: 'TOILET',
          subtitle: 'Toilet · ${item['gender_type'] ?? 'Universal'}',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: item['cleanliness_status'] ?? 'Cleaned Recently',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 5. Shelters
    for (final item in snapshot.shelters) {
      final name = item['name'] as String? ?? 'Pilgrim Shelter';
      final desc = item['address'] as String? ?? 'Overnight Stay';
      if (matches(name, desc, 'shelter') || q.contains('stay') || q.contains('rest') || q.contains('hall')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'shelter_${results.length}',
          title: name,
          category: 'SHELTER',
          subtitle: 'Shelter · Capacity: ${item['total_capacity'] ?? 200}',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: 'Current Occupancy: ${item['current_occupancy'] ?? 50}',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 6. Wellness Centres
    for (final item in snapshot.wellnessCentres) {
      final name = item['name'] as String? ?? 'Foot Massage & Rest Centre';
      final desc = item['services'] as String? ?? 'Wellness Aid';
      if (matches(name, desc, 'wellness') || q.contains('massage') || q.contains('foot') || q.contains('rest')) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'wellness_${results.length}',
          title: name,
          category: 'WELLNESS',
          subtitle: 'Wellness · Foot Care & Relief',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: 'Available Services',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // 7. Resource Distributions (NGO Aid)
    for (final item in snapshot.resourceDistributions) {
      final title = item['title'] as String? ?? 'NGO Aid Distribution';
      final desc = item['description'] as String? ?? '';
      final cat = item['category'] as String? ?? 'OTHER';
      if (matches(title, desc, cat)) {
        final lat = (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude;
        final lon = (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude;
        results.add(OfflineSearchResult(
          id: item['id']?.toString() ?? 'dist_${results.length}',
          title: title,
          category: 'DISTRIBUTION',
          subtitle: 'NGO Aid · ${item['ngo_name'] ?? 'NGO Coordinator'}',
          latitude: lat,
          longitude: lon,
          distanceKm: calcDistance(lat, lon),
          statusInfo: 'Remaining: ${item['remaining_quantity'] ?? 0} ${item['unit'] ?? 'units'}',
          snapshotTimestamp: snapshot.relativeAgeString,
          rawData: item,
        ));
      }
    }

    // Sort results by distance if available
    if (userLat != null && userLon != null) {
      results.sort((a, b) {
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm!.compareTo(b.distanceKm!);
      });
    }

    return results;
  }
}
