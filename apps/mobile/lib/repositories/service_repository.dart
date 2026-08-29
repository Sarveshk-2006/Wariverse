import '../services/api_service.dart';
import '../models/models_exports.dart';

typedef ServiceResult<T> = ({List<T> items, bool isFromMock});

/// Repository for all pilgrim service endpoints:
/// food, water, toilets, shelters, medical, wellness.
class ServiceRepository {
  ServiceRepository(this._api);

  final ApiService _api;

  Future<ServiceResult<FoodCentre>> getFoodCentres({
    double? lat,
    double? lon,
    double radiusKm = 5.0,
  }) async {
    final query = lat != null
        ? {'lat': '$lat', 'lon': '$lon', 'radius_km': '$radiusKm'}
        : null;
    final path = lat != null ? '/food/nearby' : '/food';
    try {
      final data = await _api.get(path, query: query);
      final items = (data as List<dynamic>)
          .map((e) => FoodCentre.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <FoodCentre>[], isFromMock: false);
    }
  }

  Future<ServiceResult<WaterPoint>> getWaterPoints({double? lat, double? lon}) async {
    final query = lat != null ? {'lat': '$lat', 'lon': '$lon'} : null;
    final path = lat != null ? '/water/nearby' : '/water';
    try {
      final data = await _api.get(path, query: query);
      final items = (data as List<dynamic>)
          .map((e) => WaterPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <WaterPoint>[], isFromMock: false);
    }
  }

  Future<ServiceResult<ToiletPoint>> getToilets() async {
    try {
      final data = await _api.get('/toilets');
      final items = (data as List<dynamic>)
          .map((e) => ToiletPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <ToiletPoint>[], isFromMock: false);
    }
  }

  Future<ServiceResult<Shelter>> getShelters() async {
    try {
      final data = await _api.get('/shelters');
      final items = (data as List<dynamic>)
          .map((e) => Shelter.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <Shelter>[], isFromMock: false);
    }
  }

  Future<ServiceResult<MedicalLocation>> getMedicalLocations() async {
    try {
      final data = await _api.get('/medical');
      final items = (data as List<dynamic>)
          .map((e) => MedicalLocation.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <MedicalLocation>[], isFromMock: false);
    }
  }

  Future<ServiceResult<WellnessCentre>> getWellnessCentres() async {
    try {
      final data = await _api.get('/wellness');
      final items = (data as List<dynamic>)
          .map((e) => WellnessCentre.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (_) {
      return (items: <WellnessCentre>[], isFromMock: false);
    }
  }
}
