import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/dindi_location_repository.dart';

/// State provider for real-time and simulated live Dindi route navigation.
class DindiRouteProvider extends ChangeNotifier {
  final DindiLocationRepository _locationRepository;

  DindiRouteProvider({required DindiLocationRepository locationRepository})
      : _locationRepository = locationRepository;

  StreamSubscription<DindiLocationUpdate>? _sub;
  DindiLocationUpdate? _currentLocation;
  bool _autoFollow = true;
  bool _isTracking = false;
  bool _isPaused = false;

  DindiLocationUpdate? get currentLocation => _currentLocation;
  bool get autoFollow => _autoFollow;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;

  /// Starts subscribing to location stream for a specific Dindi.
  void startTracking({String dindiId = 'dindi-001'}) {
    _sub?.cancel();
    _isTracking = true;
    _isPaused = false;
    notifyListeners();

    _locationRepository.startSimulation(dindiId: dindiId);
    _sub = _locationRepository.locationStream.listen((update) {
      _currentLocation = update;
      notifyListeners();
    });
  }

  void toggleAutoFollow([bool? value]) {
    _autoFollow = value ?? !_autoFollow;
    notifyListeners();
  }

  void pauseTracking() {
    _isPaused = true;
    _locationRepository.pauseSimulation();
    notifyListeners();
  }

  void resumeTracking() {
    _isPaused = false;
    _locationRepository.resumeSimulation();
    notifyListeners();
  }

  void resetTracking() {
    _locationRepository.resetSimulation();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _locationRepository.dispose();
    super.dispose();
  }
}
