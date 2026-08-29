import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/nearby_services_engine.dart';
import 'package:mobile/models/unified_service_item.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NearbyServicesEngine Unit Tests', () {
    test('Haversine distance calculation is accurate', () {
      // Pune (18.5204, 73.8567) to Hadapsar (18.5089, 73.9260) ~ 7.3 km
      final distMeters = NearbyServicesEngine.calculateHaversineDistanceMeters(
        18.5204,
        73.8567,
        18.5089,
        73.9260,
      );

      expect(distMeters, greaterThan(7000.0));
      expect(distMeters, lessThan(8000.0));
    });

    test('Zero coordinates return default large distance without crashing', () {
      final dist = NearbyServicesEngine.calculateHaversineDistanceMeters(0.0, 0.0, 18.5204, 73.8567);
      expect(dist, equals(99999.0));
    });

    test('Nearest & Best ranking prioritizes active and closer facilities', () {
      final closeItem = UnifiedServiceItem(
        id: 'srv_1',
        name: 'Nearby Medical Camp',
        categoryKey: 'medical',
        categoryLabel: 'Medical',
        icon: Icons.local_hospital,
        color: Colors.red,
        latitude: 18.5210,
        longitude: 73.8570,
        availableNow: true,
      );

      final farItem = UnifiedServiceItem(
        id: 'srv_2',
        name: 'Far Away Medical Camp',
        categoryKey: 'medical',
        categoryLabel: 'Medical',
        icon: Icons.local_hospital,
        color: Colors.red,
        latitude: 18.5230,
        longitude: 73.8580,
        availableNow: true,
      );

      final ranked = NearbyServicesEngine.rankAndFilterServices(
        allItems: [farItem, closeItem],
        userLat: 18.5204,
        userLng: 73.8567,
      );

      expect(ranked.items.length, equals(2));
      expect(ranked.items.first.id, equals('srv_1'));
    });

    test('Smart radius auto-expands tier when no items match tight radius', () {
      final distantItem = UnifiedServiceItem(
        id: 'srv_dist',
        name: 'Extended Annadan Tent',
        categoryKey: 'food',
        categoryLabel: 'Food',
        icon: Icons.restaurant,
        color: Colors.orange,
        latitude: 18.5350,
        longitude: 73.8700,
        availableNow: true,
      );

      final result = NearbyServicesEngine.rankAndFilterServices(
        allItems: [distantItem],
        userLat: 18.5204,
        userLng: 73.8567,
        initialRadiusTier: SearchRadiusTier.veryNearby, // 500m
      );

      expect(result.autoExpanded, isTrue);
      expect(result.items.length, equals(1));
      expect(result.items.first.id, equals('srv_dist'));
    });
  });
}
