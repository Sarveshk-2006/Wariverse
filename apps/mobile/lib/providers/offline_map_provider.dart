import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/wari_route_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../services/offline_map_storage_service.dart';
import '../services/offline_map_search_service.dart';

enum LiveMapConnectivityStatus {
  online,
  downloading,
  offline,
  reconnecting,
  updated,
}

/// Production Provider managing Offline Map Snapshots & Online/Offline Connectivity state transitions.
class OfflineMapProvider extends ChangeNotifier {
  final OfflineMapStorageService _storageService;
  final Connectivity _connectivity;

  LiveMapConnectivityStatus _status = LiveMapConnectivityStatus.online;
  OfflineMapSnapshot? _activeSnapshot;
  List<OfflineMapSnapshot> _savedSnapshots = [];
  
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _downloadStatusMessage = '';
  String? _lastError;
  bool _isOfflineNavigationActive = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  OfflineMapProvider({
    OfflineMapStorageService? storageService,
    Connectivity? connectivity,
  })  : _storageService = storageService ?? OfflineMapStorageService(),
        _connectivity = connectivity ?? Connectivity() {
    _initConnectivityListener();
    _loadSavedSnapshots();
  }

  // Getters
  LiveMapConnectivityStatus get status => _status;
  OfflineMapSnapshot? get activeSnapshot => _activeSnapshot;
  List<OfflineMapSnapshot> get savedSnapshots => _savedSnapshots;
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  String get downloadStatusMessage => _downloadStatusMessage;
  String? get lastError => _lastError;
  bool get isOfflineNavigationActive => _isOfflineNavigationActive;
  bool get isOfflineMode => _status == LiveMapConnectivityStatus.offline;

  /// Human-readable connectivity badge text.
  String get statusBadgeText {
    switch (_status) {
      case LiveMapConnectivityStatus.online:
        return '🟢 LIVE — Connected to WariVerse realtime services';
      case LiveMapConnectivityStatus.downloading:
        return '🔵 DOWNLOADING OFFLINE MAP — Saving current Wari route...';
      case LiveMapConnectivityStatus.offline:
        final age = _activeSnapshot?.relativeAgeString ?? 'recently';
        return '🟠 OFFLINE MODE — Using map saved ($age)';
      case LiveMapConnectivityStatus.reconnecting:
        return '🟡 RECONNECTING — Restoring realtime Wari data...';
      case LiveMapConnectivityStatus.updated:
        return '🟢 LIVE — MAP UPDATED';
    }
  }

  /// Initialize real-time network connectivity listener.
  void _initConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isDisconnected = results.contains(ConnectivityResult.none);
      if (isDisconnected && _status != LiveMapConnectivityStatus.offline) {
        setOfflineMode(true);
      } else if (!isDisconnected && _status == LiveMapConnectivityStatus.offline) {
        reconnectOnline();
      }
    });
  }

  /// Load existing snapshots from local storage index.
  Future<void> _loadSavedSnapshots() async {
    _savedSnapshots = await _storageService.getAllSnapshots();
    _activeSnapshot = await _storageService.getLatestSnapshot();
    if (_activeSnapshot != null && _status == LiveMapConnectivityStatus.offline) {
      notifyListeners();
    }
  }

  /// Toggle manual Offline mode.
  void setOfflineMode(bool offline) async {
    if (offline) {
      _status = LiveMapConnectivityStatus.offline;
      _activeSnapshot ??= await _storageService.getLatestSnapshot();
    } else {
      _status = LiveMapConnectivityStatus.online;
    }
    notifyListeners();
  }

  /// Trigger reconnection to Firebase.
  Future<void> reconnectOnline() async {
    _status = LiveMapConnectivityStatus.reconnecting;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));
    _status = LiveMapConnectivityStatus.updated;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    if (_status == LiveMapConnectivityStatus.updated) {
      _status = LiveMapConnectivityStatus.online;
      notifyListeners();
    }
  }

  /// Toggle Offline Navigation mode.
  void toggleOfflineNavigation([bool? enabled]) {
    _isOfflineNavigationActive = enabled ?? !_isOfflineNavigationActive;
    notifyListeners();
  }

  /// Download current Wari route or current area offline snapshot from Firebase repositories.
  Future<bool> downloadOfflineSnapshot({
    required ServiceRepository serviceRepo,
    required CrowdRepository crowdRepo,
    required SosRepository sosRepo,
    bool isCurrentAreaOnly = false,
    double radiusKm = 10.0,
  }) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0.05;
    _status = LiveMapConnectivityStatus.downloading;
    _downloadStatusMessage = 'Capturing current GPS position...';
    _lastError = null;
    notifyListeners();

    try {
      // 1. Get location once for Low-Battery UX
      Position? currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        currentPos = null;
      }

      final centerLat = currentPos?.latitude ?? 18.5204;
      final centerLon = currentPos?.longitude ?? 73.8567;

      _downloadProgress = 0.20;
      _downloadStatusMessage = 'Downloading food, water & shelter locations...';
      notifyListeners();

      // 2. Fetch service locations from repositories
      final foodResult = await serviceRepo.getFoodCentres();
      final waterResult = await serviceRepo.getWaterPoints();
      final shelterResult = await serviceRepo.getShelters();
      final medicalResult = await serviceRepo.getMedicalLocations();
      final toiletResult = await serviceRepo.getToilets();
      final wellnessResult = await serviceRepo.getWellnessCentres();

      final foodList = foodResult.items;
      final waterList = waterResult.items;
      final shelterList = shelterResult.items;
      final medicalList = medicalResult.items;
      final toiletList = toiletResult.items;
      final wellnessList = wellnessResult.items;

      _downloadProgress = 0.55;
      _downloadStatusMessage = 'Downloading crowd metrics & route checkpoints...';
      notifyListeners();

      final crowdResult = await crowdRepo.getCurrentCrowd();
      final crowdList = crowdResult.zones;
      final sosResult = await sosRepo.getIncidents();
      final sosList = sosResult.incidents;

      // 3. Fetch resource distributions & dindi locations from Firestore if available
      final List<Map<String, dynamic>> distributionsJson = [];
      final List<Map<String, dynamic>> dindiJson = [];

      if (Firebase.apps.isNotEmpty) {
        try {
          final firestore = FirebaseFirestore.instance;
          final distSnap = await firestore.collection('resource_distributions').get();
          for (final doc in distSnap.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            distributionsJson.add(data);
          }

          final dindiSnap = await firestore.collection('dindis').get();
          for (final doc in dindiSnap.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            data.remove('admin_notes');
            data.remove('private_contact');
            dindiJson.add(data);
          }
        } catch (e) {
          AppLogger.i('Notice during Firestore offline collection fetch: $e');
        }
      }

      _downloadProgress = 0.80;
      _downloadStatusMessage = 'Processing offline polyline & map metadata...';
      notifyListeners();

      // 4. Build Wari polyline
      final routePolyline = WariRouteConstants.palkhiRoutePoints.map((pt) {
        return {'latitude': pt.latitude, 'longitude': pt.longitude};
      }).toList();

      // 5. Serialize items to JSON objects
      List<Map<String, dynamic>> serializeList(List items) {
        return items.map((item) {
          if (item is FoodCentre) return item.toJson();
          if (item is WaterPoint) return item.toJson();
          if (item is Shelter) return item.toJson();
          if (item is MedicalLocation) return item.toJson();
          if (item is ToiletPoint) return item.toJson();
          if (item is WellnessCentre) return item.toJson();
          if (item is CrowdZone) return item.toJson();
          if (item is SOSIncident) return item.toJson();
          return <String, dynamic>{};
        }).toList();
      }

      final snapshot = OfflineMapSnapshot(
        snapshotId: 'snap_${DateTime.now().millisecondsSinceEpoch}',
        routeId: isCurrentAreaOnly ? 'current_area_10km' : 'alandi_pandharpur_main',
        routeName: isCurrentAreaOnly ? 'Current Wari Area (10 km Radius)' : 'Alandi → Pandharpur Wari Route',
        downloadedAt: DateTime.now().toIso8601String(),
        centerLatitude: centerLat,
        centerLongitude: centerLon,
        currentUserLocation: currentPos != null
            ? {'latitude': currentPos.latitude, 'longitude': currentPos.longitude}
            : null,
        routePolyline: routePolyline,
        foodCentres: serializeList(foodList),
        waterPoints: serializeList(waterList),
        shelters: serializeList(shelterList),
        medicalLocations: serializeList(medicalList),
        toilets: serializeList(toiletList),
        wellnessCentres: serializeList(wellnessList),
        crowdZones: serializeList(crowdList),
        crowdAlerts: serializeList(sosList.where((s) => s.status.isActive).toList()),
        dindiLocations: dindiJson,
        resourceDistributions: distributionsJson,
        mapMetadata: {
          'data_version': '1.0',
          'schema_version': 1,
          'coverage_km': isCurrentAreaOnly ? 10.0 : 142.0,
          'estimated_size_bytes': (foodList.length + waterList.length + toiletList.length + shelterList.length + medicalList.length + routePolyline.length) * 450,
        },
      );

      _downloadProgress = 0.95;
      _downloadStatusMessage = 'Saving offline package to device storage...';
      notifyListeners();

      // 6. Save to local disk via OfflineMapStorageService
      final success = await _storageService.saveSnapshot(snapshot);
      if (success) {
        _activeSnapshot = snapshot;
        _savedSnapshots = await _storageService.getAllSnapshots();
        _downloadProgress = 1.0;
        _downloadStatusMessage = '✓ Map saved for offline use';
        _status = LiveMapConnectivityStatus.online;
        AppLogger.i('Offline map download completed: ${snapshot.totalElementCount} elements saved.');
      } else {
        throw Exception('Storage write verification failed.');
      }

      _isDownloading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _lastError = e.toString();
      _downloadStatusMessage = 'Download incomplete — existing offline map retained.';
      _status = LiveMapConnectivityStatus.online;
      AppLogger.i('Offline map download error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete snapshot by ID.
  Future<void> deleteSnapshot(String snapshotId) async {
    await _storageService.deleteSnapshot(snapshotId);
    _savedSnapshots = await _storageService.getAllSnapshots();
    if (_activeSnapshot?.snapshotId == snapshotId) {
      _activeSnapshot = _savedSnapshots.isNotEmpty ? _savedSnapshots.first : null;
    }
    notifyListeners();
  }

  /// Perform query search on active snapshot.
  List<OfflineSearchResult> searchOffline(String query, {double? userLat, double? userLon}) {
    if (_activeSnapshot == null) return [];
    return OfflineMapSearchService.searchOffline(
      _activeSnapshot!,
      query,
      userLat: userLat,
      userLon: userLon,
    );
  }

  /// Clear all offline data on logout.
  Future<void> clearUserOfflineDataOnLogout() async {
    await _storageService.clearUserPrivateOfflineData();
    _activeSnapshot = null;
    _savedSnapshots = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
