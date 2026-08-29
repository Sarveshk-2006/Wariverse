import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/app_exception.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/services/mock_data_source.dart';

void main() {
  group('JSON Parsing & Domain Models Tests', () {
    test('AppUser fromJson parses correctly', () {
      final json = {
        'user_id': 'u123',
        'role': 'VARKARI',
        'display_name': 'Tukaram Maharaj',
        'access_token': 'demo-jwt-token',
      };
      final user = AppUser.fromJson(json);
      expect(user.userId, 'u123');
      expect(user.userRole, UserRole.VARKARI);
      expect(user.displayName, 'Tukaram Maharaj');
      expect(user.isDemoMode, true);
    });

    test('CrowdZone fromJson parses correctly', () {
      final json = MockDataSource.crowdCurrent.first;
      final zone = CrowdZone.fromJson(json);
      expect(zone.id, 'z1');
      expect(zone.crowdLevel, CrowdLevel.RED);
      expect(zone.currentDensity, 0.92);
      expect(zone.estimatedCount, 45000);
    });

    test('SOSIncident fromJson parses correctly', () {
      final json = MockDataSource.sos.first;
      final incident = SOSIncident.fromJson(json);
      expect(incident.id, 'sos1');
      expect(incident.category, SOSCategory.MEDICAL);
      expect(incident.status, SOSStatus.ACKNOWLEDGED);
      expect(incident.responderName, 'Dr. Priya Kulkarni');
    });

    test('FoodCentre fromJson parses correctly', () {
      final json = MockDataSource.food.first;
      final food = FoodCentre.fromJson(json);
      expect(food.id, 'f1');
      expect(food.provider, 'ISKCON Seva Trust');
      expect(food.capacity, 20000);
      expect(food.mealTypes.contains('LUNCH'), true);
    });
  });

  group('Error Handling & Exception Tests', () {
    test('AppException factory constructors create proper error codes', () {
      final timeoutErr = AppException.timeout();
      expect(timeoutErr.code, AppErrorCode.timeout);
      expect(timeoutErr.isNetworkError, true);

      final noInternetErr = AppException.noInternet();
      expect(noInternetErr.code, AppErrorCode.noInternet);
      expect(noInternetErr.isNetworkError, true);

      final httpErr = AppException.http(401, 'Unauthorized');
      expect(httpErr.code, AppErrorCode.unauthorized);
      expect(httpErr.isNetworkError, false);
    });

    test('AppException identifies mock fallback eligibility', () {
      expect(AppException.timeout().isMockFallbackEligible, true);
      expect(AppException.noInternet().isMockFallbackEligible, true);
      expect(AppException.serverUnavailable().isMockFallbackEligible, true);
      expect(AppException.http(404, 'Not Found').isMockFallbackEligible, false);
    });
  });

  group('Mock Data & Environment Configuration Tests', () {
    test('MockDataSource contains expected default datasets', () {
      expect(MockDataSource.crowdCurrent.isNotEmpty, true);
      expect(MockDataSource.food.length, 3);
      expect(MockDataSource.water.length, 3);
      expect(MockDataSource.sos.length, 2);
    });

    test('MockDataSource login helper returns valid demo user tokens', () {
      final varkariLogin = MockDataSource.mockLogin('varkari@wariverse.demo');
      expect(varkariLogin, isNotNull);
      expect(varkariLogin!['role'], 'VARKARI');

      final invalidLogin = MockDataSource.mockLogin('invalid@example.com');
      expect(invalidLogin, isNull);
    });

    test('EnvConfig resolves fallback URL correctly', () {
      expect(EnvConfig.apiBaseUrl.startsWith('http'), true);
    });
  });
}
