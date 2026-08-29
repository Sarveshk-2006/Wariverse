import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';

/// Emergency Distress Loud Siren Service (Extracted from WoShield2 BuzzerActivity).
class EmergencySirenService with ChangeNotifier {
  bool _isSirenActive = false;

  bool get isSirenActive => _isSirenActive;

  void toggleSiren() {
    _isSirenActive = !_isSirenActive;
    if (_isSirenActive) {
      AppLogger.i('🚨 LOUD DISTRESS SIREN ACTIVATED (100dB Emergency Alarm)');
    } else {
      AppLogger.i('🔇 Loud Distress Siren Silenced');
    }
    notifyListeners();
  }

  void startSiren() {
    if (!_isSirenActive) {
      _isSirenActive = true;
      AppLogger.i('🚨 LOUD DISTRESS SIREN ACTIVATED');
      notifyListeners();
    }
  }

  void stopSiren() {
    if (_isSirenActive) {
      _isSirenActive = false;
      AppLogger.i('🔇 Loud Distress Siren Silenced');
      notifyListeners();
    }
  }
}
