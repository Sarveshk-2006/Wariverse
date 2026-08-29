import 'dart:math' as math;
import '../../models/unified_service_item.dart';

/// Configurable search radii tiers for Nearby Services.
enum SearchRadiusTier {
  veryNearby(500.0, '0–500m (Very Nearby)'),
  nearby(1000.0, '500m–1km (Nearby)'),
  extendedNearby(3000.0, '1–3km (Extended Nearby)'),
  routeWide(15000.0, '3–15km (Palkhi Route Wide)');

  final double radiusMeters;
  final String label;
  const SearchRadiusTier(this.radiusMeters, this.label);
}

/// Geospatial distance calculation and "Nearest & Best" multi-factor ranking engine.
class NearbyServicesEngine {
  /// Calculates Haversine distance in meters between two GPS coordinates.
  static double calculateHaversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == 0.0 || lon1 == 0.0 || lat2 == 0.0 || lon2 == 0.0) {
      return 99999.0;
    }

    const double earthRadiusMeters = 6371000.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Estimates walking time in minutes based on average walking speed (4.5 km/h ≈ 75 m/min).
  static int estimateWalkMinutes(double distanceMeters) {
    return (distanceMeters / 75.0).ceil();
  }

  /// Multi-factor "Nearest & Best" ranking algorithm.
  /// Combines distance, operational availability, remaining capacity/stock, and category priority.
  static double computeRankingScore(
    UnifiedServiceItem item,
    double distanceMeters,
  ) {
    final double distanceWeight = 10000.0 / math.max(10.0, distanceMeters);
    final double availabilityMultiplier = item.availableNow ? 1.5 : 0.1;
    final double capacityBonus = (item.capacity ?? 0) > 0 ? 1.2 : 1.0;

    return distanceWeight * availabilityMultiplier * capacityBonus;
  }

  /// Ranks, filters, and dynamically auto-expands search radius if no active services match tight radius.
  static ({
    List<UnifiedServiceItem> items,
    SearchRadiusTier activeRadiusTier,
    bool autoExpanded,
  }) rankAndFilterServices({
    required List<UnifiedServiceItem> allItems,
    required double userLat,
    required double userLng,
    String categoryFilter = 'ALL',
    SearchRadiusTier initialRadiusTier = SearchRadiusTier.veryNearby,
  }) {
    if (allItems.isEmpty) {
      return (items: [], activeRadiusTier: initialRadiusTier, autoExpanded: false);
    }

    SearchRadiusTier currentTier = initialRadiusTier;
    bool autoExpanded = false;
    List<UnifiedServiceItem> filtered = [];

    // Attempt filtering starting at initial radius tier and expanding if empty
    final tiers = [
      SearchRadiusTier.veryNearby,
      SearchRadiusTier.nearby,
      SearchRadiusTier.extendedNearby,
      SearchRadiusTier.routeWide,
    ];

    int startIndex = tiers.indexOf(initialRadiusTier);
    if (startIndex == -1) startIndex = 0;

    for (int i = startIndex; i < tiers.length; i++) {
      currentTier = tiers[i];

      final candidateList = <UnifiedServiceItem>[];
      for (final rawItem in allItems) {
        final distM = calculateHaversineDistanceMeters(
          userLat,
          userLng,
          rawItem.latitude,
          rawItem.longitude,
        );

        if (distM <= currentTier.radiusMeters) {
          // Category matching
          if (categoryFilter != 'ALL') {
            final catKey = rawItem.categoryKey.toUpperCase();
            final targetKey = categoryFilter.toUpperCase();
            if (catKey != targetKey && !_categoryMatchesGroup(catKey, targetKey)) {
              continue;
            }
          }

          // Create updated item copy with distance and walk minutes
          final updatedItem = UnifiedServiceItem(
            id: rawItem.id,
            name: rawItem.name,
            categoryKey: rawItem.categoryKey,
            categoryLabel: rawItem.categoryLabel,
            icon: rawItem.icon,
            color: rawItem.color,
            latitude: rawItem.latitude,
            longitude: rawItem.longitude,
            availableNow: rawItem.availableNow,
            distanceM: distM.toInt(),
            walkMinutes: estimateWalkMinutes(distM),
            queueMinutes: rawItem.queueMinutes,
            capacity: rawItem.capacity,
            rating: rawItem.rating,
            subtext: rawItem.subtext,
            tags: rawItem.tags,
            originalModel: rawItem.originalModel,
          );

          candidateList.add(updatedItem);
        }
      }

      if (candidateList.isNotEmpty) {
        filtered = candidateList;
        if (i > startIndex) autoExpanded = true;
        break;
      }
    }

    // Sort primarily by computeRankingScore descending
    filtered.sort((a, b) {
      final scoreA = computeRankingScore(a, a.distanceM?.toDouble() ?? 9999.0);
      final scoreB = computeRankingScore(b, b.distanceM?.toDouble() ?? 9999.0);
      return scoreB.compareTo(scoreA);
    });

    return (items: filtered, activeRadiusTier: currentTier, autoExpanded: autoExpanded);
  }

  static bool _categoryMatchesGroup(String catKey, String targetKey) {
    if (targetKey == 'FOOD' && (catKey == 'ANNADAN' || catKey == 'MEALS')) return true;
    if (targetKey == 'MEDICAL' && (catKey == 'HOSPITAL' || catKey == 'FIRST_AID')) return true;
    if (targetKey == 'WATER' && catKey == 'HYDRATION') return true;
    if (targetKey == 'TOILETS' && catKey == 'SANITATION') return true;
    return false;
  }
}
