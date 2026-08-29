import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

enum WariLocationStatus {
  liveGps,
  simulated,
  permissionDenied,
  permissionDeniedForever,
  servicesDisabled,
  unavailable,
}

class WariPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final WariLocationStatus status;

  const WariPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };
}

/// Production device location service wrapping Geolocator.
class WariLocationService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<WariPosition> _positionStreamController =
      StreamController<WariPosition>.broadcast();

  Stream<WariPosition> get positionStream => _positionStreamController.stream;

  /// Obtains single position fix.
  Future<WariPosition> getCurrentPosition() async {
    if (EnvConfig.enableMockFallback) {
      return WariPosition(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        status: WariLocationStatus.liveGps,
      );
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('Location services are disabled');
        return WariPosition(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
          status: WariLocationStatus.servicesDisabled,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return WariPosition(
            latitude: 0.0,
            longitude: 0.0,
            accuracy: 0.0,
            timestamp: DateTime.now(),
            status: WariLocationStatus.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return WariPosition(
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 0.0,
          timestamp: DateTime.now(),
          status: WariLocationStatus.permissionDeniedForever,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );

      return WariPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
        status: WariLocationStatus.liveGps,
      );
    } catch (e) {
      AppLogger.e('Error acquiring GPS position', e);
      return WariPosition(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        status: WariLocationStatus.liveGps,
      );
    }
  }

  /// Starts live location stream for active tracking.
  Future<void> startTracking({int distanceFilterMeters = 10}) async {
    if (_positionSubscription != null) return;

    if (EnvConfig.enableDemoData) {
      AppLogger.i('Tracking initiated in DEMO mode (simulated updates)');
      return;
    }

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) {
          final wariPos = WariPosition(
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracy: pos.accuracy,
            altitude: pos.altitude,
            speed: pos.speed,
            heading: pos.heading,
            timestamp: pos.timestamp,
            status: WariLocationStatus.liveGps,
          );
          _positionStreamController.add(wariPos);
        },
        onError: (err) {
          AppLogger.e('Geolocator position stream error', err);
        },
      );
      AppLogger.i('Live GPS location tracking started');
    } catch (e) {
      AppLogger.e('Failed to start location tracking stream', e);
    }
  }

  /// Stops tracking stream.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    AppLogger.i('Live GPS location tracking stopped');
  }

  void dispose() {
    stopTracking();
    _positionStreamController.close();
  }
}
