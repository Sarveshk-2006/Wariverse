// ignore_for_file: constant_identifier_names

/// Application environment tiers for WariVerse AI.
enum AppEnvironment {
  demo,
  development,
  production,
}

extension AppEnvironmentX on AppEnvironment {
  String get name {
    switch (this) {
      case AppEnvironment.demo:        return 'DEMO';
      case AppEnvironment.development: return 'DEVELOPMENT';
      case AppEnvironment.production:  return 'PRODUCTION';
    }
  }

  bool get isDemo => this == AppEnvironment.demo;
  bool get isDevelopment => this == AppEnvironment.development;
  bool get isProduction => this == AppEnvironment.production;
}
