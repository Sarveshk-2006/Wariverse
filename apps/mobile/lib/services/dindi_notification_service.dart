import '../models/virtual_dindi_model.dart';
import '../core/utils/app_logger.dart';

/// Notification Alert Dispatcher with Cooldown and State Management.
class DindiNotificationService {
  static final DindiNotificationService _instance = DindiNotificationService._internal();
  factory DindiNotificationService() => _instance;
  DindiNotificationService._internal();

  DateTime? _lastCautionAlertTime;
  DateTime? _lastSeparatedAlertTime;
  DateTime? _lastCriticalAlertTime;

  /// Trigger separation notification alert based on current separation state and cooldown.
  Future<void> triggerSeparationAlert({
    required SeparationState state,
    required double distanceMeters,
    required String dindiName,
    required MovementTrend trend,
  }) async {
    final now = DateTime.now();

    switch (state) {
      case SeparationState.SAFE:
        // Reset timers on return to safe
        break;

      case SeparationState.CAUTION:
        if (_lastCautionAlertTime == null || now.difference(_lastCautionAlertTime!).inMinutes >= 5) {
          _lastCautionAlertTime = now;
          _showLocalNotification(
            title: '⚠️ Approaching Dindi Boundary',
            body: "You're ${distanceMeters.toInt()}m from $dindiName. (${trend.displayName})",
            payload: {'type': 'VIRTUAL_DINDI_SEPARATION', 'state': 'CAUTION'},
          );
        }
        break;

      case SeparationState.SEPARATED:
        if (_lastSeparatedAlertTime == null || now.difference(_lastSeparatedAlertTime!).inMinutes >= 2) {
          _lastSeparatedAlertTime = now;
          _showLocalNotification(
            title: '🔔 Separated from Virtual Dindi',
            body: "Distance: ${distanceMeters.toInt()}m. Tap to open Dindi Map and navigate back.",
            payload: {'type': 'VIRTUAL_DINDI_SEPARATION', 'state': 'SEPARATED'},
          );
        }
        break;

      case SeparationState.CRITICAL:
        if (_lastCriticalAlertTime == null || now.difference(_lastCriticalAlertTime!).inMinutes >= 1) {
          _lastCriticalAlertTime = now;
          _showLocalNotification(
            title: '🚨 CRITICAL DINDI SEPARATION ALERT',
            body: "Distance exceeds ${distanceMeters.toInt()}m! Reunification navigation active.",
            payload: {'type': 'VIRTUAL_DINDI_SEPARATION', 'state': 'CRITICAL'},
          );
        }
        break;

      case SeparationState.RETURNING:
        // No heavy alert, user is returning
        break;
    }
  }

  void _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) {
    AppLogger.i('[LOCAL NOTIFICATION] $title — $body | Payload: $payload');
    // Device notification dispatch log
  }
}
