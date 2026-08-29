import '../services/api_service.dart';
import '../services/mock_data_source.dart';
import '../models/models_exports.dart';
import '../core/errors/app_exception.dart';
import '../core/config/env_config.dart';

class AiRepository {
  AiRepository(this._api);

  final ApiService _api;

  Future<({AiRecommendation recommendation, bool isFromMock})> recommendFood({
    double? lat,
    double? lon,
  }) async {
    final query = lat != null ? {'lat': '$lat', 'lon': '$lon'} : null;
    try {
      final data = await _api.get('/ai/recommend-food', query: query);
      return (
        recommendation: AiRecommendation.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        return (
          recommendation: AiRecommendation.fromJson(MockDataSource.aiRecommendFood),
          isFromMock: true,
        );
      }
      rethrow;
    }
  }

  Future<({AiRecommendation recommendation, bool isFromMock})> recommendWater({
    double? lat,
    double? lon,
  }) async {
    final query = lat != null ? {'lat': '$lat', 'lon': '$lon'} : null;
    try {
      final data = await _api.get('/ai/recommend-water', query: query);
      return (
        recommendation: AiRecommendation.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        return (
          recommendation: AiRecommendation.fromJson(MockDataSource.aiRecommendWater),
          isFromMock: true,
        );
      }
      rethrow;
    }
  }

  Future<({ResourcePrediction prediction, bool isFromMock})> predictResources() async {
    try {
      final data = await _api.get('/resources/prediction');
      return (
        prediction: ResourcePrediction.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        // Fallback stub for resources prediction
        final mockPrediction = {
          'total_pilgrims_estimate': 1450000,
          'food': {
            'shortage_risk': 'HIGH',
            'recommendation': 'Divert 2000 meals to Wakhari Camp immediately.',
          },
          'water': {
            'shortage_risk': 'LOW',
            'recommendation': 'Water supply is stable.',
          },
          'medical': {
            'shortage_risk': 'MEDIUM',
            'recommendation': 'Deploy 2 additional mobile clinics to Ghat zone.',
          },
        };
        return (
          prediction: ResourcePrediction.fromJson(mockPrediction),
          isFromMock: true,
        );
      }
      rethrow;
    }
  }
}
