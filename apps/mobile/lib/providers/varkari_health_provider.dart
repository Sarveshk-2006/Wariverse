import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/weather_repository.dart';
import '../services/health_risk_engine.dart';

/// Provider managing Varkari Health Shield heat and dehydration risk awareness state.
class VarkariHealthProvider extends ChangeNotifier {
  final WeatherRepository _weatherRepository;

  VarkariHealthProvider({required WeatherRepository weatherRepository})
      : _weatherRepository = weatherRepository;

  VarkariHealthRisk? _currentRisk;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  VarkariHealthRisk? get currentRisk => _currentRisk;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  /// Loads current weather and evaluates health risk.
  Future<void> loadHealthRisk({DindiLocationUpdate? movement}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _weatherRepository.getWeather();
      _currentRisk = HealthRiskEngine.calculateRisk(
        weather: res.weather,
        movement: movement,
        isDemo: res.isFromMock,
      );
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Unable to load health risk awareness data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
