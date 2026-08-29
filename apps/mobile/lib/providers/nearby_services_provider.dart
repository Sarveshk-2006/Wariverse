import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/unified_service_item.dart';
import '../models/models_exports.dart';
import '../services/api_service.dart';
import '../services/wari_location_service.dart';
import '../repositories/service_repository.dart';
import '../core/utils/nearby_services_engine.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

enum NearbyNetworkStatus {
  live,
  syncing,
  offline,
}

/// Centralized Provider managing Real-Time Nearby Location-Based Services for Varkari.
class NearbyServicesProvider with ChangeNotifier {
  final WariLocationService _locationService;
  final ServiceRepository _serviceRepo;

  StreamSubscription<WariPosition>? _positionSub;
  WariPosition? _currentPosition;
  double _lastProcessedLat = 0.0;
  double _lastProcessedLng = 0.0;

  List<UnifiedServiceItem> _rawServices = [];
  List<UnifiedServiceItem> _nearbyServices = [];
  List<ResourceDistribution> _ngoDeployments = [];

  String _activeCategory = 'ALL';
  SearchRadiusTier _activeRadiusTier = SearchRadiusTier.veryNearby;
  bool _autoExpandedRadius = false;
  bool _isLoading = false;
  NearbyNetworkStatus _networkStatus = NearbyNetworkStatus.live;

  NearbyServicesProvider({
    WariLocationService? locationService,
    ServiceRepository? serviceRepo,
    ApiService? apiService,
  })  : _locationService = locationService ?? WariLocationService(),
        _serviceRepo = serviceRepo ?? ServiceRepository(apiService ?? ApiService()) {
    _initLocationListener();
    _loadCachedServices();
  }

  bool _isLocationUnavailable = false;
  WariLocationStatus _locationStatus = WariLocationStatus.liveGps;

  // Getters
  List<UnifiedServiceItem> get nearbyServices => List.unmodifiable(_nearbyServices);
  WariPosition? get currentPosition => _currentPosition;
  String get activeCategory => _activeCategory;
  SearchRadiusTier get activeRadiusTier => _activeRadiusTier;
  bool get autoExpandedRadius => _autoExpandedRadius;
  bool get isLoading => _isLoading;
  NearbyNetworkStatus get networkStatus => _networkStatus;
  bool get isLocationUnavailable => _isLocationUnavailable;
  WariLocationStatus get locationStatus => _locationStatus;

  void setActiveCategory(String category) {
    if (_activeCategory != category) {
      _activeCategory = category;
      _recalculateNearby();
    }
  }

  void setSearchRadiusTier(SearchRadiusTier tier) {
    _activeRadiusTier = tier;
    _recalculateNearby();
  }

  /// Updates live NGO deployments stream from NgoDistributionProvider.
  void updateNgoDeployments(List<ResourceDistribution> deployments) {
    if (_ngoDeployments.length == deployments.length && listEquals(_ngoDeployments, deployments)) {
      return;
    }
    _ngoDeployments = deployments;
    _syncRawServices();
  }

  void _initLocationListener() {
    _loadServicesFromSources();
    if (EnvConfig.enableMockFallback) return;

    _locationService.getCurrentPosition().then((pos) {
      _locationStatus = pos.status;
      if (pos.latitude != 0.0 && pos.longitude != 0.0) {
        _currentPosition = pos;
        _lastProcessedLat = pos.latitude;
        _lastProcessedLng = pos.longitude;
        _isLocationUnavailable = false;
      } else {
        _isLocationUnavailable = pos.status == WariLocationStatus.servicesDisabled ||
            pos.status == WariLocationStatus.permissionDenied ||
            pos.status == WariLocationStatus.permissionDeniedForever ||
            pos.status == WariLocationStatus.unavailable;
      }
      _loadServicesFromSources();
    }).catchError((_) {
      _isLocationUnavailable = true;
      _loadServicesFromSources();
    });

    _locationService.startTracking(distanceFilterMeters: 15);
    _positionSub = _locationService.positionStream.listen((pos) {
      if (pos.latitude == 0.0 || pos.longitude == 0.0) return;
      _currentPosition = pos;
      _locationStatus = pos.status;
      _isLocationUnavailable = false;

      final movedMeters = NearbyServicesEngine.calculateHaversineDistanceMeters(
        _lastProcessedLat,
        _lastProcessedLng,
        pos.latitude,
        pos.longitude,
      );

      if (movedMeters > 15.0) {
        _lastProcessedLat = pos.latitude;
        _lastProcessedLng = pos.longitude;
        _recalculateNearby();
      }
    });
  }

  Future<void> _loadServicesFromSources() async {
    _isLoading = true;
    _networkStatus = NearbyNetworkStatus.syncing;
    notifyListeners();

    try {
      final lat = _currentPosition?.latitude ?? 18.5204;
      final lon = _currentPosition?.longitude ?? 73.8567;

      final results = await Future.wait([
        _serviceRepo.getFoodCentres(lat: lat, lon: lon),
        _serviceRepo.getWaterPoints(lat: lat, lon: lon),
        _serviceRepo.getMedicalLocations(),
        _serviceRepo.getToilets(),
        _serviceRepo.getShelters(),
        _serviceRepo.getWellnessCentres(),
      ]);

      final foodRes = results[0] as ({List<FoodCentre> items, bool isFromMock});
      final waterRes = results[1] as ({List<WaterPoint> items, bool isFromMock});
      final medRes = results[2] as ({List<MedicalLocation> items, bool isFromMock});
      final toiletRes = results[3] as ({List<ToiletPoint> items, bool isFromMock});
      final shelterRes = results[4] as ({List<Shelter> items, bool isFromMock});
      final wellnessRes = results[5] as ({List<WellnessCentre> items, bool isFromMock});

      final items = <UnifiedServiceItem>[];
      for (final f in foodRes.items) {
        items.add(UnifiedServiceItem.fromFood(f));
      }
      for (final w in waterRes.items) {
        items.add(UnifiedServiceItem.fromWater(w));
      }
      for (final m in medRes.items) {
        items.add(UnifiedServiceItem.fromMedical(m));
      }
      for (final t in toiletRes.items) {
        items.add(UnifiedServiceItem.fromToilet(t));
      }
      for (final s in shelterRes.items) {
        items.add(UnifiedServiceItem.fromShelter(s));
      }
      for (final wc in wellnessRes.items) {
        items.add(UnifiedServiceItem.fromWellness(wc));
      }

      _rawServices = items;
      _syncRawServices();
      _networkStatus = NearbyNetworkStatus.live;
      _cacheServicesLocally();
    } catch (e) {
      AppLogger.e('Error loading nearby services from sources', e);
      _networkStatus = NearbyNetworkStatus.offline;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Merges standard services and NGO real-time resource deployments into unified list.
  void _syncRawServices() {
    final merged = List<UnifiedServiceItem>.from(_rawServices);

    // Adapt active NGO Resource Distributions into UnifiedServiceItem
    for (final ngoItem in _ngoDeployments) {
      if (!ngoItem.isActive) continue;

      final adapted = UnifiedServiceItem(
        id: 'ngo_${ngoItem.id}',
        name: ngoItem.title,
        categoryKey: ngoItem.category.name.toLowerCase(),
        categoryLabel: '${ngoItem.ngoName} Aid',
        icon: ngoItem.category.icon,
        color: ngoItem.category.color,
        latitude: ngoItem.latitude,
        longitude: ngoItem.longitude,
        availableNow: ngoItem.remainingQuantity > 0,
        capacity: ngoItem.quantity,
        subtext: '${ngoItem.remainingQuantity}/${ngoItem.quantity} ${ngoItem.unit} remaining',
        tags: [ngoItem.computedAvailabilityStatus, ngoItem.locationName],
        originalModel: ngoItem,
      );

      merged.add(adapted);
    }

    _rawServices = merged;
    _recalculateNearby();
  }

  void _recalculateNearby() {
    final lat = _currentPosition?.latitude ?? 18.5204;
    final lon = _currentPosition?.longitude ?? 73.8567;

    final res = NearbyServicesEngine.rankAndFilterServices(
      allItems: _rawServices,
      userLat: lat,
      userLng: lon,
      categoryFilter: _activeCategory,
      initialRadiusTier: _activeRadiusTier,
    );

    _nearbyServices = res.items;
    _autoExpandedRadius = res.autoExpanded;
    notifyListeners();
  }

  Future<void> _cacheServicesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _rawServices.map((s) => {
        'id': s.id,
        'name': s.name,
        'category_key': s.categoryKey,
        'category_label': s.categoryLabel,
        'latitude': s.latitude,
        'longitude': s.longitude,
        'available_now': s.availableNow,
        'subtext': s.subtext,
      }).toList();
      await prefs.setString('cached_nearby_services', jsonEncode(listJson));
    } catch (_) {}
  }

  Future<void> _loadCachedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_nearby_services');
      if (str != null && str.isNotEmpty) {
        final List<dynamic> list = jsonDecode(str);
        _rawServices = list.map((m) => UnifiedServiceItem(
          id: m['id'] as String,
          name: m['name'] as String,
          categoryKey: m['category_key'] as String,
          categoryLabel: m['category_label'] as String,
          icon: DistributionCategoryX.fromString(m['category_key'] as String).icon,
          color: DistributionCategoryX.fromString(m['category_key'] as String).color,
          latitude: (m['latitude'] as num).toDouble(),
          longitude: (m['longitude'] as num).toDouble(),
          availableNow: m['available_now'] as bool? ?? true,
          subtext: m['subtext'] as String?,
        )).toList();
        _recalculateNearby();
      }
    } catch (_) {}
  }

  Future<void> refresh() => _loadServicesFromSources();

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
