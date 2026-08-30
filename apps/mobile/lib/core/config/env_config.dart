import 'app_environment.dart';

/// Dynamic, build-time environment configuration for WariVerse AI mobile client.
///
/// Build flags:
///   --dart-define=APP_ENV=demo | development | production
///   --dart-define=API_URL=http://10.0.2.2:8000
///   --dart-define=WS_URL=ws://10.0.2.2:8000/ws
class EnvConfig {
  static const String _envString = String.fromEnvironment('APP_ENV', defaultValue: 'demo');
  static const String _overrideApiUrl = String.fromEnvironment('API_URL');
  static const String _overrideWsUrl = String.fromEnvironment('WS_URL');
  static const String _platform = String.fromEnvironment('PLATFORM');
  static const String oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');


  static const String _androidEmulatorApiUrl = 'http://10.0.2.2:8000';
  static const String _iosSimulatorApiUrl = 'http://127.0.0.1:8000';
  static const String _productionApiUrl = 'https://api.wariverse.app';

  static const String _androidEmulatorWsUrl = 'ws://10.0.2.2:8000/ws';
  static const String _iosSimulatorWsUrl = 'ws://127.0.0.1:8000/ws';
  static const String _productionWsUrl = 'wss://api.wariverse.app/ws';

  /// Centralized Operations Web application base URL.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://web-one-tau-17.vercel.app',
  );

  /// Resolved Web Admin Command Center Dashboard URL.
  static String get adminDashboardUrl => '$webBaseUrl/dashboard/admin';

  /// Resolved Web NGO Operations Dashboard URL.
  static String get ngoDashboardUrl => '$webBaseUrl/dashboard/ngo';

  /// Resolves current environment enum.
  static AppEnvironment get currentEnvironment {
    switch (_envString.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'demo':
      default:
        return AppEnvironment.demo;
    }
  }

  /// Resolved API Base URL.
  static String get apiBaseUrl {
    if (_overrideApiUrl.isNotEmpty) return _overrideApiUrl;
    if (currentEnvironment.isProduction) return _productionApiUrl;
    if (_platform.toLowerCase() == 'ios') return _iosSimulatorApiUrl;
    return _androidEmulatorApiUrl;
  }

  /// Resolved WebSocket Base URL.
  static String get websocketUrl {
    if (_overrideWsUrl.isNotEmpty) return _overrideWsUrl;
    if (currentEnvironment.isProduction) return _productionWsUrl;
    if (_platform.toLowerCase() == 'ios') return _iosSimulatorWsUrl;
    return _androidEmulatorWsUrl;
  }

  /// Mock fallback is allowed ONLY in DEMO and DEVELOPMENT modes.
  /// In PRODUCTION mode, it is strictly FALSE.
  static bool get enableMockFallback {
    if (currentEnvironment.isProduction) return false;
    return true;
  }

  /// Demo data flags are active ONLY in DEMO mode.
  static bool get enableDemoData => currentEnvironment.isDemo;

  /// Debug logging is active ONLY in DEMO and DEVELOPMENT modes.
  static bool get enableDebugLogging => !currentEnvironment.isProduction;

  static const int connectTimeoutSeconds = 8;
}
