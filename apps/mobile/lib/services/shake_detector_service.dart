import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';

/// Shake Detector Service ported from WoShield2 (ShakeDetector.java).
/// Triggers emergency callback when accelerometer detects strong physical shake gesture.
class ShakeDetectorService {
  final VoidCallback onShake;
  bool _isListening = false;
  static const double shakeThreshold = 12.0;
  static const int shakeIntervalMs = 800;
  int _lastShakeTime = 0;

  ShakeDetectorService({required this.onShake});

  bool get isListening => _isListening;

  void startListening() {
    _isListening = true;
    AppLogger.i('ShakeDetectorService started monitoring shake gesture.');
  }

  void stopListening() {
    _isListening = false;
  }

  /// Evaluates accelerometer acceleration values (x, y, z).
  void processAccelerometerValues(double x, double y, double z) {
    if (!_isListening) return;

    final double gX = x / 9.80665;
    final double gY = y / 9.80665;
    final double gZ = z / 9.80665;

    final double gForce = (gX * gX + gY * gY + gZ * gZ);
    if (gForce > 2.5) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastShakeTime > shakeIntervalMs) {
        _lastShakeTime = now;
        AppLogger.i('🚨 Hardware Shake Gesture Detected! Triggering Emergency SOS.');
        onShake();
      }
    }
  }
}
