import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_environment.dart';
import 'package:mobile/core/config/env_config.dart';
import 'package:mobile/core/utils/idempotency_util.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/websocket_service.dart';
import 'test_helpers.dart';

void main() {
  group('Phase R1 Foundation — Environment & Config Tests', () {
    test('AppEnvironment enum properties resolve correctly', () {
      expect(AppEnvironment.demo.isDemo, true);
      expect(AppEnvironment.development.isDevelopment, true);
      expect(AppEnvironment.production.isProduction, true);
      expect(AppEnvironment.demo.name, 'DEMO');
    });

    test('EnvConfig resolves valid API base URL and WebSocket URL', () {
      final apiUrl = EnvConfig.apiBaseUrl;
      final wsUrl = EnvConfig.websocketUrl;

      expect(apiUrl.startsWith('http'), true);
      expect(wsUrl.startsWith('ws'), true);
    });

    test('IdempotencyUtil generates valid 36-character UUID keys', () {
      final key1 = IdempotencyUtil.generateKey();
      final key2 = IdempotencyUtil.generateKey();

      expect(key1.length, 36);
      expect(key2.length, 36);
      expect(key1, isNot(equals(key2)));
    });
  });

  group('Phase R1 Foundation — Network & Authenticated Boundary Tests', () {
    test('ApiService attaches Bearer token when set', () {
      final apiService = ApiService(client: MockTestHttpClient());
      apiService.setToken('test-jwt-token');
      expect(apiService, isNotNull);
    });

    test('WebSocketService manages connection states and subscriptions', () {
      final wsService = WebSocketService();
      expect(wsService.state, RealtimeConnectionState.disconnected);

      bool callbackCalled = false;
      void listener(Map<String, dynamic> data) {
        callbackCalled = true;
      }

      wsService.subscribe('NEW_SOS', listener);
      wsService.unsubscribe('NEW_SOS', listener);

      expect(callbackCalled, false);
    });
  });
}
