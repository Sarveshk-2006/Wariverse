import '../services/api_service.dart';
import '../services/mock_data_source.dart';
import '../models/models_exports.dart';
import '../core/errors/app_exception.dart';
import '../core/config/env_config.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiService _api;

  Future<({AdminAnalytics analytics, bool isFromMock})> getAnalytics() async {
    try {
      final data = await _api.get('/admin/analytics');
      return (
        analytics: AdminAnalytics.fromJson(data as Map<String, dynamic>),
        isFromMock: false,
      );
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        return (
          analytics: AdminAnalytics.fromJson(MockDataSource.adminAnalytics),
          isFromMock: true,
        );
      }
      rethrow;
    }
  }

  Future<({List<PoliceRoute> routes, bool isFromMock})> getPoliceRoutes() async {
    try {
      final data = await _api.get('/police/routes');
      final routes = (data as List<dynamic>)
          .map((e) => PoliceRoute.fromJson(e as Map<String, dynamic>))
          .toList();
      return (routes: routes, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        final routes = MockDataSource.policeRoutes
            .map(PoliceRoute.fromJson)
            .toList();
        return (routes: routes, isFromMock: true);
      }
      rethrow;
    }
  }

  Future<({List<VolunteerSummary> volunteers, bool isFromMock})> getVolunteers() async {
    try {
      final data = await _api.get('/ngo/volunteers');
      final volunteers = (data as List<dynamic>)
          .map((e) => VolunteerSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return (volunteers: volunteers, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        final volunteers = MockDataSource.volunteers
            .map(VolunteerSummary.fromJson)
            .toList();
        return (volunteers: volunteers, isFromMock: true);
      }
      rethrow;
    }
  }

  Future<({List<ResourceInventoryItem> resources, bool isFromMock})> getResources() async {
    try {
      final data = await _api.get('/ngo/resources');
      final resources = (data as List<dynamic>)
          .map((e) => ResourceInventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return (resources: resources, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        final resources = MockDataSource.resources
            .map(ResourceInventoryItem.fromJson)
            .toList();
        return (resources: resources, isFromMock: true);
      }
      rethrow;
    }
  }
}
