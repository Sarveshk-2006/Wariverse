import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/services/offline_map_storage_service.dart';
import 'package:mobile/services/offline_map_search_service.dart';
import 'package:mobile/providers/offline_map_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OfflineMapSnapshot Model Tests', () {
    test('OfflineMapSnapshot serialization & deserialization works correctly', () {
      final snapshot = OfflineMapSnapshot(
        snapshotId: 'snap_test_100',
        routeId: 'alandi_pandharpur',
        routeName: 'Alandi → Pandharpur Wari Route',
        downloadedAt: '2026-08-29T20:00:00.000Z',
        centerLatitude: 18.5204,
        centerLongitude: 73.8567,
        currentUserLocation: {'latitude': 18.5204, 'longitude': 73.8567},
        routePolyline: [
          {'latitude': 18.5204, 'longitude': 73.8567},
          {'latitude': 17.6741, 'longitude': 75.3279},
        ],
        foodCentres: [
          {'id': 'f1', 'name': 'Akurdi Food Camp', 'latitude': 18.64, 'longitude': 73.77, 'is_available': true},
        ],
        waterPoints: [
          {'id': 'w1', 'name': 'Bhakti Water Tap', 'latitude': 18.65, 'longitude': 73.78, 'is_functional': true},
        ],
        shelters: [
          {'id': 's1', 'name': 'Pandharpur Rest Hall', 'latitude': 17.67, 'longitude': 75.32, 'total_capacity': 500},
        ],
        medicalLocations: [
          {'id': 'm1', 'name': 'Sanjeevani Medical Camp', 'latitude': 18.66, 'longitude': 73.79, 'ambulance_available': true},
        ],
        toilets: [
          {'id': 't1', 'name': 'Mobile Sanitation Block 4', 'latitude': 18.67, 'longitude': 73.80, 'cleanliness_status': 'Clean'},
        ],
        wellnessCentres: [
          {'id': 'wel1', 'name': 'Charan Seva Massager', 'latitude': 18.68, 'longitude': 73.81},
        ],
        crowdZones: [
          {'id': 'c1', 'name': 'Temple Plaza', 'crowd_level': 'HIGH'},
        ],
        crowdAlerts: [],
        dindiLocations: [
          {'id': 'd1', 'name': 'Dindi No. 12', 'route': 'Pune Route'},
        ],
        resourceDistributions: [
          {'id': 'res1', 'title': 'Khichdi Distribution', 'category': 'FOOD', 'remaining_quantity': 400},
        ],
        mapMetadata: {'data_version': '1.0', 'estimated_size_bytes': 15000},
      );

      expect(snapshot.totalElementCount, equals(9));
      expect(snapshot.estimatedSizeMb, greaterThan(0.0));

      final json = snapshot.toJson();
      expect(json['snapshot_id'], equals('snap_test_100'));

      final rebuilt = OfflineMapSnapshot.fromJson(json);
      expect(rebuilt.snapshotId, equals('snap_test_100'));
      expect(rebuilt.routeName, equals('Alandi → Pandharpur Wari Route'));
      expect(rebuilt.foodCentres.length, equals(1));
      expect(rebuilt.waterPoints.first['name'], equals('Bhakti Water Tap'));
      expect(rebuilt.totalElementCount, equals(9));
    });
  });

  group('OfflineMapStorageService & Search Tests', () {
    test('Storage service saves, retrieves, and clears offline snapshots', () async {
      final storage = OfflineMapStorageService();

      final snapshot = OfflineMapSnapshot(
        snapshotId: 'snap_test_storage',
        routeId: 'alandi_pandharpur',
        routeName: 'Alandi → Pandharpur Wari Route',
        downloadedAt: DateTime.now().toIso8601String(),
        centerLatitude: 18.5204,
        centerLongitude: 73.8567,
        routePolyline: [],
        foodCentres: [{'id': 'f1', 'name': 'Annadan Food Stall', 'latitude': 18.52, 'longitude': 73.85}],
        waterPoints: [{'id': 'w1', 'name': 'Clean Water Point', 'latitude': 18.53, 'longitude': 73.86}],
        shelters: [],
        medicalLocations: [{'id': 'm1', 'name': 'Emergency First Aid', 'latitude': 18.54, 'longitude': 73.87}],
        toilets: [{'id': 't1', 'name': 'CleanWari Toilet Block', 'latitude': 18.55, 'longitude': 73.88}],
        wellnessCentres: [],
        crowdZones: [],
        crowdAlerts: [],
        dindiLocations: [],
        resourceDistributions: [],
        mapMetadata: {},
      );

      final saveSuccess = await storage.saveSnapshot(snapshot);
      expect(saveSuccess, isTrue);

      final loaded = await storage.getLatestSnapshot();
      expect(loaded, isNotNull);
      expect(loaded!.snapshotId, equals('snap_test_storage'));

      final all = await storage.getAllSnapshots();
      expect(all.length, greaterThanOrEqualTo(1));

      // Test Offline Search
      final searchResults = OfflineMapSearchService.searchOffline(
        loaded,
        'water',
        userLat: 18.52,
        userLon: 73.85,
      );
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.first.title, equals('Clean Water Point'));

      final medicalResults = OfflineMapSearchService.searchOffline(
        loaded,
        'medical',
        userLat: 18.52,
        userLon: 73.85,
      );
      expect(medicalResults.isNotEmpty, isTrue);
      expect(medicalResults.first.category, equals('MEDICAL'));

      // Test Signout Cleanup
      await storage.clearUserPrivateOfflineData();
      final afterClear = await storage.getLatestSnapshot();
      expect(afterClear, isNull);
    });
  });

  group('OfflineMapProvider Connectivity & State Tests', () {
    test('OfflineMapProvider handles offline mode and snapshot management', () async {
      final provider = OfflineMapProvider();

      expect(provider.status, equals(LiveMapConnectivityStatus.online));
      expect(provider.isOfflineMode, isFalse);

      provider.setOfflineMode(true);
      expect(provider.status, equals(LiveMapConnectivityStatus.offline));
      expect(provider.isOfflineMode, isTrue);
      expect(provider.statusBadgeText, contains('OFFLINE MODE'));

      provider.toggleOfflineNavigation(true);
      expect(provider.isOfflineNavigationActive, isTrue);

      await provider.reconnectOnline();
      expect(provider.status, equals(LiveMapConnectivityStatus.online));
    });
  });
}
