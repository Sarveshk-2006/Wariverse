import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/wari_theme_exports.dart';
import '../models/map_marker_item.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../core/constants/wari_route_constants.dart';
import '../services/wari_location_service.dart';

import '../core/config/env_config.dart';

class MapProvider extends ChangeNotifier {
  MapProvider({
    required ServiceRepository serviceRepo,
    required CrowdRepository crowdRepo,
    required SosRepository sosRepo,
    FirebaseFirestore? firestore,
  })  : _serviceRepo = serviceRepo,
        _crowdRepo = crowdRepo,
        _sosRepo = sosRepo,
        _firestore = firestore ?? (EnvConfig.enableMockFallback ? null : FirebaseFirestore.instance);

  final ServiceRepository _serviceRepo;
  final CrowdRepository _crowdRepo;
  final SosRepository _sosRepo;
  final FirebaseFirestore? _firestore;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isFromMock = false;
  String _activeLayer = 'all';
  MapMarkerItem? _selectedMarker;
  bool _showReportModal = false;

  List<MapMarkerItem> _allMarkers = [];
  List<CrowdZone> _crowdZones = [];
  LatLng _userLocation = WariRouteConstants.pandharpurCenter;
  final double _userHeading = 0.0;
  String? _crowdWarning;

  final List<StreamSubscription> _subscriptions = [];

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isFromMock => _isFromMock;
  String get activeLayer => _activeLayer;
  MapMarkerItem? get selectedMarker => _selectedMarker;
  bool get showReportModal => _showReportModal;
  List<CrowdZone> get crowdZones => _crowdZones;
  LatLng get userLocation => _userLocation;
  double get userHeading => _userHeading;
  String? get crowdWarning => _crowdWarning;

  List<MapMarkerItem> get filteredMarkers {
    if (_activeLayer == 'all') return _allMarkers;
    return _allMarkers.where((m) => m.layer == _activeLayer || m.layer == 'user').toList();
  }

  void setActiveLayer(String layerKey) {
    if (_activeLayer != layerKey) {
      _activeLayer = layerKey;
      _selectedMarker = null;
      notifyListeners();
    }
  }

  void selectMarker(MapMarkerItem? marker) {
    _selectedMarker = marker;
    notifyListeners();
  }

  void setShowReportModal(bool value) {
    _showReportModal = value;
    notifyListeners();
  }

  /// Calculates real distance in meters between two lat/lng points using Haversine formula.
  static double calculateDistanceMeters(LatLng p1, LatLng p2) {
    const double r = 6371000;
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Get nearest amenities derived strictly from real GPS location and map markers.
  List<MapMarkerItem> getNearbyServices({int limit = 5}) {
    final items = _allMarkers.where((m) => m.layer != 'user').toList();
    items.sort((a, b) {
      final dA = calculateDistanceMeters(_userLocation, a.location);
      final dB = calculateDistanceMeters(_userLocation, b.location);
      return dA.compareTo(dB);
    });
    return items.take(limit).toList();
  }

  /// Initialize real-time data loading & Firestore listeners.
  Future<void> loadMapData() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final currentPos = await WariLocationService().getCurrentPosition();
      _userLocation = LatLng(currentPos.latitude, currentPos.longitude);

      final results = await Future.wait([
        _serviceRepo.getFoodCentres(lat: _userLocation.latitude, lon: _userLocation.longitude),
        _serviceRepo.getWaterPoints(lat: _userLocation.latitude, lon: _userLocation.longitude),
        _serviceRepo.getMedicalLocations(),
        _serviceRepo.getToilets(),
        _serviceRepo.getShelters(),
        _serviceRepo.getWellnessCentres(),
        _crowdRepo.getCurrentCrowd(),
        _sosRepo.getIncidents(),
      ]);

      final foodRes = results[0] as ({List<FoodCentre> items, bool isFromMock});
      final waterRes = results[1] as ({List<WaterPoint> items, bool isFromMock});
      final medRes = results[2] as ({List<MedicalLocation> items, bool isFromMock});
      final toiletRes = results[3] as ({List<ToiletPoint> items, bool isFromMock});
      final shelterRes = results[4] as ({List<Shelter> items, bool isFromMock});
      final wellnessRes = results[5] as ({List<WellnessCentre> items, bool isFromMock});
      final crowdRes = results[6] as ({List<CrowdZone> zones, bool isFromMock});
      final sosRes = results[7] as ({List<SOSIncident> incidents, bool isFromMock});

      _crowdZones = crowdRes.zones;
      _isFromMock = foodRes.isFromMock || waterRes.isFromMock || crowdRes.isFromMock;

      _rebuildMarkerList(
        foodCentres: foodRes.items,
        waterPoints: waterRes.items,
        medicalLocations: medRes.items,
        toilets: toiletRes.items,
        shelters: shelterRes.items,
        wellnessCentres: wellnessRes.items,
        sosIncidents: sosRes.incidents,
      );

      _checkCrowdWarnings();
      _setupFirestoreListeners();
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _rebuildMarkerList({
    required List<FoodCentre> foodCentres,
    required List<WaterPoint> waterPoints,
    required List<MedicalLocation> medicalLocations,
    required List<ToiletPoint> toilets,
    required List<Shelter> shelters,
    required List<WellnessCentre> wellnessCentres,
    required List<SOSIncident> sosIncidents,
  }) {
    final items = <MapMarkerItem>[];

    items.add(MapMarkerItem(
      id: 'user-location',
      title: 'Your Current Location',
      layer: 'user',
      latitude: _userLocation.latitude,
      longitude: _userLocation.longitude,
      icon: Icons.my_location,
      color: WariColors.primary,
      statusLabel: 'Active GPS',
    ));

    for (final f in foodCentres) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(f.latitude, f.longitude));
      items.add(MapMarkerItem(
        id: f.id,
        title: f.name,
        layer: 'food',
        latitude: f.latitude,
        longitude: f.longitude,
        icon: MapMarkerItem.getLayerIcon('food'),
        color: MapMarkerItem.getLayerColor('food'),
        statusLabel: f.availableNow ? 'Open Now' : 'Closed',
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        queueMinutes: f.estimatedQueueMinutes,
        availableNow: f.availableNow,
        originalData: f,
      ));
    }

    for (final w in waterPoints) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(w.latitude, w.longitude));
      items.add(MapMarkerItem(
        id: w.id,
        title: w.name,
        layer: 'water',
        latitude: w.latitude,
        longitude: w.longitude,
        icon: MapMarkerItem.getLayerIcon('water'),
        color: MapMarkerItem.getLayerColor('water'),
        statusLabel: w.status.name,
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: true,
        originalData: w,
      ));
    }

    for (final m in medicalLocations) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(m.latitude, m.longitude));
      items.add(MapMarkerItem(
        id: m.id,
        title: m.name,
        layer: 'medical',
        latitude: m.latitude,
        longitude: m.longitude,
        icon: MapMarkerItem.getLayerIcon('medical'),
        color: MapMarkerItem.getLayerColor('medical'),
        statusLabel: m.operatingHours,
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: m.available,
        originalData: m,
      ));
    }

    for (final t in toilets) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(t.latitude, t.longitude));
      items.add(MapMarkerItem(
        id: t.id,
        title: t.name,
        layer: 'toilets',
        latitude: t.latitude,
        longitude: t.longitude,
        icon: MapMarkerItem.getLayerIcon('toilets'),
        color: MapMarkerItem.getLayerColor('toilets'),
        statusLabel: t.status.name,
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: true,
        originalData: t,
      ));
    }

    for (final s in shelters) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(s.latitude, s.longitude));
      items.add(MapMarkerItem(
        id: s.id,
        title: s.name,
        layer: 'shelters',
        latitude: s.latitude,
        longitude: s.longitude,
        icon: MapMarkerItem.getLayerIcon('shelters'),
        color: MapMarkerItem.getLayerColor('shelters'),
        statusLabel: '${s.availableSpots} spots left',
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: s.availableNow,
        originalData: s,
      ));
    }

    for (final wc in wellnessCentres) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(wc.latitude, wc.longitude));
      items.add(MapMarkerItem(
        id: wc.id,
        title: wc.name,
        layer: 'wellness',
        latitude: wc.latitude,
        longitude: wc.longitude,
        icon: MapMarkerItem.getLayerIcon('wellness'),
        color: MapMarkerItem.getLayerColor('wellness'),
        statusLabel: 'Open',
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: wc.availableNow,
        originalData: wc,
      ));
    }

    for (final s in sosIncidents) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(s.latitude, s.longitude));
      items.add(MapMarkerItem(
        id: s.id,
        title: 'SOS: ${s.category.displayName}',
        layer: 'sos',
        latitude: s.latitude,
        longitude: s.longitude,
        icon: MapMarkerItem.getLayerIcon('sos'),
        color: MapMarkerItem.getLayerColor('sos'),
        statusLabel: s.status.displayName,
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: true,
        originalData: s,
      ));
    }

    _allMarkers = items;
  }

  void _checkCrowdWarnings() {
    _crowdWarning = null;
    for (final zone in _crowdZones) {
      if (zone.crowdLevel == CrowdLevel.RED || zone.crowdLevel == CrowdLevel.ORANGE) {
        final dist = calculateDistanceMeters(_userLocation, zone.location);
        if (dist <= 600) {
          _crowdWarning = 'Heavy crowd ahead in ${zone.name} (${dist.toInt()}m away). Exercise caution.';
          break;
        }
      }
    }
  }

  void _setupFirestoreListeners() {
    _cancelSubscriptions();
    final firestore = _firestore;
    if (firestore == null || EnvConfig.enableMockFallback || Firebase.apps.isEmpty) return;

    try {
      final sosSub = firestore.collection('sos_incidents').snapshots().listen((snapshot) {
        final incidents = snapshot.docs.map((doc) => SOSIncident.fromSnapshot(doc)).toList();
        _updateSosMarkers(incidents);
      });
      _subscriptions.add(sosSub);

      final crowdSub = firestore.collection('crowd_zones').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _crowdZones = snapshot.docs.map((doc) {
            final data = doc.data();
            return CrowdZone(
              id: doc.id,
              name: data['name'] ?? 'Crowd Zone',
              crowdLevel: _parseCrowdLevel(data['crowd_level']),
              currentDensity: (data['current_density'] as num?)?.toDouble() ?? 0.0,
              estimatedCount: (data['estimated_count'] as num?)?.toInt() ?? 0,
              latitude: (data['latitude'] as num?)?.toDouble() ?? 17.6741,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 75.3279,
              radiusM: (data['radius_m'] as num?)?.toDouble() ?? 300.0,
            );
          }).toList();
          _checkCrowdWarnings();
          notifyListeners();
        }
      });
      _subscriptions.add(crowdSub);

      final resourceSub = firestore.collection('resource_deployments').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final distributions = snapshot.docs.map((doc) {
            final d = doc.data();
            d['id'] = doc.id;
            return ResourceDistribution.fromJson(d);
          }).toList();
          _updateResourceDistributionMarkers(distributions);
        }
      });
      _subscriptions.add(resourceSub);
    } catch (_) {}
  }

  CrowdLevel _parseCrowdLevel(dynamic level) {
    final str = (level ?? '').toString().toUpperCase();
    if (str.contains('CRITICAL') || str.contains('RED')) return CrowdLevel.RED;
    if (str.contains('HIGH') || str.contains('ORANGE')) return CrowdLevel.ORANGE;
    if (str.contains('MODERATE') || str.contains('YELLOW')) return CrowdLevel.YELLOW;
    return CrowdLevel.GREEN;
  }

  void _updateSosMarkers(List<SOSIncident> incidents) {
    _allMarkers.removeWhere((m) => m.layer == 'sos');
    for (final s in incidents) {
      final dist = calculateDistanceMeters(_userLocation, LatLng(s.latitude, s.longitude));
      _allMarkers.add(MapMarkerItem(
        id: s.id,
        title: 'SOS: ${s.category.displayName}',
        layer: 'sos',
        latitude: s.latitude,
        longitude: s.longitude,
        icon: MapMarkerItem.getLayerIcon('sos'),
        color: MapMarkerItem.getLayerColor('sos'),
        statusLabel: s.status.displayName,
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: true,
        originalData: s,
      ));
    }
    notifyListeners();
  }

  void _updateResourceDistributionMarkers(List<ResourceDistribution> distributions) {
    _allMarkers.removeWhere((m) => m.layer == 'ngo_distribution');
    for (final d in distributions) {
      if (!d.isActive) continue;
      final dist = calculateDistanceMeters(_userLocation, LatLng(d.latitude, d.longitude));
      _allMarkers.add(MapMarkerItem(
        id: d.id,
        title: '${d.title} (${d.remainingQuantity} ${d.unit})',
        layer: d.category.name.toLowerCase() == 'food' ? 'food' : 'ngo_distribution',
        latitude: d.latitude,
        longitude: d.longitude,
        icon: d.category.icon,
        color: d.category.color,
        statusLabel: '${d.remainingQuantity} ${d.unit} remaining',
        distanceM: dist.toInt(),
        walkMinutes: (dist / 80).ceil(),
        availableNow: true,
        originalData: d,
      ));
    }
    notifyListeners();
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> refresh() => loadMapData();

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
