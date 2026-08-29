import 'package:flutter/material.dart';
import '../core/utils/app_logger.dart';

/// Centralized notification deep-link navigation handler for WariVerse AI.
class NotificationNavigationHandler {
  static final NotificationNavigationHandler _instance = NotificationNavigationHandler._internal();
  factory NotificationNavigationHandler() => _instance;
  NotificationNavigationHandler._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Configures the root navigator key for deep-link navigation.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Evaluates notification payload dictionary and navigates safely to target route.
  void handleNotificationPayload(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return;

    final type = data['type'] as String?;
    final route = data['route'] as String?;
    final incidentId = data['incident_id'] as String?;
    final dindiId = data['dindi_id'] as String?;

    AppLogger.i('Handling notification deep link — Type: $type, Route: $route, IncidentId: $incidentId');

    final context = _navigatorKey?.currentContext;
    if (context == null) {
      AppLogger.i('Navigator context is unavailable for notification navigation.');
      return;
    }

    if (route != null && route.isNotEmpty) {
      try {
        Navigator.of(context).pushNamed(
          route,
          arguments: {
            'type': type,
            'incident_id': incidentId,
            'dindi_id': dindiId,
          },
        );
      } catch (e) {
        AppLogger.e('Failed to navigate to target deep link route: $route', e);
      }
    }
  }
}
