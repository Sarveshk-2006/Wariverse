import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';

/// State provider for WariVerse AI Home Dashboard.
class HomeProvider extends ChangeNotifier {
  HomeProvider({
    required CrowdRepository crowdRepo,
    required WeatherRepository weatherRepo,
    required ServiceRepository serviceRepo,
    required SosRepository sosRepo,
    required AdminRepository adminRepo,
  })  : _crowdRepo = crowdRepo,
        _weatherRepo = weatherRepo,
        _serviceRepo = serviceRepo,
        _sosRepo = sosRepo,
        _adminRepo = adminRepo;

  final CrowdRepository _crowdRepo;
  final WeatherRepository _weatherRepo;
  final ServiceRepository _serviceRepo;
  final SosRepository _sosRepo;
  final AdminRepository _adminRepo;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isFromMock = false;

  WeatherInfo? _weather;
  List<CrowdZone> _crowdZones = [];
  CrowdPrediction? _crowdPrediction;
  List<FoodCentre> _nearbyFood = [];
  List<WaterPoint> _nearbyWater = [];
  List<SOSIncident> _activeSosIncidents = [];
  AdminAnalytics? _adminAnalytics;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isFromMock => _isFromMock;

  WeatherInfo? get weather => _weather;
  List<CrowdZone> get crowdZones => _crowdZones;
  CrowdPrediction? get crowdPrediction => _crowdPrediction;
  List<FoodCentre> get nearbyFood => _nearbyFood;
  List<WaterPoint> get nearbyWater => _nearbyWater;
  List<SOSIncident> get activeSosIncidents => _activeSosIncidents;
  AdminAnalytics? get adminAnalytics => _adminAnalytics;

  int get totalPilgrimsEstimate =>
      _crowdZones.fold(0, (sum, z) => sum + z.estimatedCount);

  CrowdLevel get highestCrowdLevel {
    if (_crowdZones.isEmpty) return CrowdLevel.GREEN;
    if (_crowdZones.any((z) => z.crowdLevel == CrowdLevel.RED)) {
      return CrowdLevel.RED;
    }
    if (_crowdZones.any((z) => z.crowdLevel == CrowdLevel.ORANGE)) {
      return CrowdLevel.ORANGE;
    }
    if (_crowdZones.any((z) => z.crowdLevel == CrowdLevel.YELLOW)) {
      return CrowdLevel.YELLOW;
    }
    return CrowdLevel.GREEN;
  }

  /// Load all Home screen data concurrently.
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _weatherRepo.getWeather(),
        _crowdRepo.getCurrentCrowd(),
        _crowdRepo.getPrediction(),
        _serviceRepo.getFoodCentres(lat: 17.6741, lon: 75.3279),
        _serviceRepo.getWaterPoints(lat: 17.6741, lon: 75.3279),
        _sosRepo.getIncidents(),
        _adminRepo.getAnalytics(),
      ]);

      final weatherRes = results[0] as ({WeatherInfo weather, bool isFromMock});
      final crowdRes = results[1] as ({List<CrowdZone> zones, bool isFromMock});
      final predRes = results[2] as ({CrowdPrediction prediction, bool isFromMock});
      final foodRes = results[3] as ({List<FoodCentre> items, bool isFromMock});
      final waterRes = results[4] as ({List<WaterPoint> items, bool isFromMock});
      final sosRes = results[5] as ({List<SOSIncident> incidents, bool isFromMock});
      final adminRes = results[6] as ({AdminAnalytics analytics, bool isFromMock});

      _weather = weatherRes.weather;
      _crowdZones = crowdRes.zones;
      _crowdPrediction = predRes.prediction;
      _nearbyFood = foodRes.items;
      _nearbyWater = waterRes.items;
      _activeSosIncidents = sosRes.incidents;
      _adminAnalytics = adminRes.analytics;

      _isFromMock = weatherRes.isFromMock || crowdRes.isFromMock || foodRes.isFromMock;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh dashboard data.
  Future<void> refresh() => loadDashboardData();
}
