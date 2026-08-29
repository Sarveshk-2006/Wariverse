import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/utils/app_logger.dart';
import '../services/api_service.dart';
import '../models/models_exports.dart';

typedef ServiceResult<T> = ({List<T> items, bool isFromMock});

/// Repository for all pilgrim service endpoints:
/// food, water, toilets, shelters, medical, wellness.
/// Fetches directly from Cloud Firestore with REST API & offline fallback.
class ServiceRepository {
  ServiceRepository(this._api, {FirebaseFirestore? firestore})
      : _firestore = firestore;

  final ApiService _api;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get firestore {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<ServiceResult<FoodCentre>> getFoodCentres({
    double? lat,
    double? lon,
    double radiusKm = 5.0,
  }) async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('food_centers').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return FoodCentre.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore food_centers notice: $e');
    }

    try {
      final query = lat != null ? {'lat': '$lat', 'lon': '$lon', 'radius_km': '$radiusKm'} : null;
      final path = lat != null ? '/food/nearby' : '/food';
      final data = await _api.get(path, query: query);
      final items = (data as List<dynamic>)
          .map((e) => FoodCentre.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        FoodCentre.fromJson({'id': 'fc_01', 'name': 'Alandi Annadan Seva Camp', 'latitude': 18.6780, 'longitude': 73.8970, 'capacity': 500, 'estimated_queue_minutes': 5, 'available_now': true, 'provider': 'Shiv Seva Foundation'}),
        FoodCentre.fromJson({'id': 'fc_02', 'name': 'Vishrantwadi Mahaprasad Pavilion', 'latitude': 18.5600, 'longitude': 73.8650, 'capacity': 800, 'estimated_queue_minutes': 10, 'available_now': true, 'provider': 'Wari Seva Trust'}),
        FoodCentre.fromJson({'id': 'fc_03', 'name': 'Hadapsar Solapur Annadan Ground', 'latitude': 18.5000, 'longitude': 73.9300, 'capacity': 1200, 'estimated_queue_minutes': 8, 'available_now': true, 'provider': 'Pandharpur Seva Mandal'}),
      ], isFromMock: true);
    }
  }

  Future<ServiceResult<WaterPoint>> getWaterPoints({double? lat, double? lon}) async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('water_points').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return WaterPoint.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore water_points notice: $e');
    }

    try {
      final query = lat != null ? {'lat': '$lat', 'lon': '$lon'} : null;
      final path = lat != null ? '/water/nearby' : '/water';
      final data = await _api.get(path, query: query);
      final items = (data as List<dynamic>)
          .map((e) => WaterPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        WaterPoint.fromJson({'id': 'wp_01', 'name': 'Dighi Pure ORS & Water Tanker', 'latitude': 18.6300, 'longitude': 73.8750, 'water_type': 'DRINKING_WATER', 'status': 'AVAILABLE', 'capacity_liters': 5000}),
        WaterPoint.fromJson({'id': 'wp_02', 'name': 'Pune Station Hydration Kiosk', 'latitude': 18.5280, 'longitude': 73.8740, 'water_type': 'DRINKING_WATER', 'status': 'AVAILABLE', 'capacity_liters': 3000}),
      ], isFromMock: true);
    }
  }

  Future<ServiceResult<ToiletPoint>> getToilets() async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('toilets').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ToiletPoint.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore toilets notice: $e');
    }

    try {
      final data = await _api.get('/toilets');
      final items = (data as List<dynamic>)
          .map((e) => ToiletPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        ToiletPoint.fromJson({'id': 'tp_01', 'name': 'Pune Station Mobile Sanitation Complex', 'latitude': 18.5280, 'longitude': 73.8740, 'total_units': 30, 'clean_status': 'CLEAN', 'gender': 'UNISEX'}),
        ToiletPoint.fromJson({'id': 'tp_02', 'name': 'Alandi Ghat Sanitation Block', 'latitude': 18.6775, 'longitude': 73.8980, 'total_units': 20, 'clean_status': 'CLEAN', 'gender': 'UNISEX'}),
      ], isFromMock: true);
    }
  }

  Future<ServiceResult<Shelter>> getShelters() async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('shelters').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Shelter.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore shelters notice: $e');
    }

    try {
      final data = await _api.get('/shelters');
      final items = (data as List<dynamic>)
          .map((e) => Shelter.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        Shelter.fromJson({'id': 'sh_01', 'name': 'Hadapsar Relief Rest Tent', 'latitude': 18.5000, 'longitude': 73.9300, 'total_beds': 200, 'available_beds': 85, 'has_medical_support': true}),
      ], isFromMock: true);
    }
  }

  Future<ServiceResult<MedicalLocation>> getMedicalLocations() async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('medical_locations').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return MedicalLocation.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore medical_locations notice: $e');
    }

    try {
      final data = await _api.get('/medical');
      final items = (data as List<dynamic>)
          .map((e) => MedicalLocation.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        MedicalLocation.fromJson({'id': 'ml_01', 'name': 'Vishrantwadi Emergency Medical Aid Post', 'latitude': 18.5600, 'longitude': 73.8650, 'doctor_count': 4, 'ambulance_available': true, 'emergency_contact': '108'}),
      ], isFromMock: true);
    }
  }

  Future<ServiceResult<WellnessCentre>> getWellnessCentres() async {
    try {
      if (firestore != null) {
        final snap = await firestore!.collection('wellness_centers').get();
        if (snap.docs.isNotEmpty) {
          final items = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return WellnessCentre.fromJson(data);
          }).toList();
          return (items: items, isFromMock: false);
        }
      }
    } catch (e) {
      AppLogger.d('Firestore wellness_centers notice: $e');
    }

    try {
      final data = await _api.get('/wellness');
      final items = (data as List<dynamic>)
          .map((e) => WellnessCentre.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, isFromMock: false);
    } catch (e) {
      return (items: [
        WellnessCentre.fromJson({'id': 'wc_01', 'name': 'Alandi Foot Massage & Seva Kendra', 'latitude': 18.6780, 'longitude': 73.8970, 'volunteers_count': 15, 'is_free_service': true}),
      ], isFromMock: true);
    }
  }
}
