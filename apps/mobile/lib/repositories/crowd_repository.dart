import '../services/api_service.dart';
import '../services/mock_data_source.dart';
import '../models/models_exports.dart';
import '../core/errors/app_exception.dart';
import '../core/config/env_config.dart';

/// Repository for crowd zone and prediction data.
class CrowdRepository {
  CrowdRepository(this._api);

  final ApiService _api;

  /// Returns current crowd zones. Falls back to mock on network failure.
  Future<({List<CrowdZone> zones, bool isFromMock})> getCurrentCrowd() async {
    try {
      final data = await _api.get('/crowd/current');
      final zones = (data as List<dynamic>)
          .map((e) => CrowdZone.fromJson(e as Map<String, dynamic>))
          .toList();
      return (zones: zones, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        final zones = MockDataSource.crowdCurrent
            .map(CrowdZone.fromJson)
            .toList();
        return (zones: zones, isFromMock: true);
      }
      rethrow;
    }
  }

  /// Returns crowd prediction data.
  Future<({CrowdPrediction prediction, bool isFromMock})> getPrediction() async {
    try {
      final data = await _api.get('/crowd/prediction');
      return (
        prediction: CrowdPrediction.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        return (
          prediction: CrowdPrediction.fromJson(MockDataSource.crowdPrediction),
          isFromMock: true,
        );
      }
      rethrow;
    }
  }
}
