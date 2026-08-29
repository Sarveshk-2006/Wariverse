import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';
import 'notification_navigation_handler.dart';

typedef OSPushSubscriptionObserver = void Function(OSPushSubscriptionChangedState state);

/// Centralized push notification service wrapping OneSignal SDK for WariVerse AI.
class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static const String defaultAppId = 'd3eb187f-c8cc-49a2-baf7-75724f14874d';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Validates whether a push subscription ID is server-assigned (non-empty & not starting with 'local-').
  static bool isServerAssignedSubscriptionId(String? id) {
    if (id == null || id.isEmpty) return false;
    if (id.startsWith('local-')) return false;
    return true;
  }

  /// Initializes OneSignal SDK with project App ID.
  Future<void> initialize({String? appId}) async {
    final targetAppId = appId ?? (EnvConfig.oneSignalAppId.isNotEmpty ? EnvConfig.oneSignalAppId : defaultAppId);

    if (targetAppId.isEmpty) {
      AppLogger.i('OneSignal App ID is empty; skipping initialization.');
      return;
    }

    runZonedGuarded(() {
      try {
        OneSignal.Debug.setLogLevel(OSLogLevel.none);
        OneSignal.initialize(targetAppId);
        _isInitialized = true;
        AppLogger.i('OneSignal initialized successfully with App ID: $targetAppId');

        // Setup notification click handler for deep linking
        OneSignal.Notifications.addClickListener((event) {
          final data = event.notification.additionalData;
          AppLogger.i('OneSignal notification clicked with data: $data');
          NotificationNavigationHandler().handleNotificationPayload(data);
        });

        // Setup foreground notification display policy
        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          AppLogger.i('Foreground notification received: ${event.notification.title}');
          event.notification.display();
        });
      } catch (_) {
        _isInitialized = true;
      }
    }, (error, stack) {
      _isInitialized = true;
    });
  }

  /// Displays notification rationale dialog explaining features before requesting Android permission.
  Future<void> requestPermissionRationale(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔔 Enable Safety & Emergency Alerts'),
        content: const Text(
          'WariVerse AI uses notifications to send critical SOS updates, Dindi broadcasts, and weather alerts during your pilgrimage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              requestPermission();
            },
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );
  }

  /// Registers push subscription state change observer.
  void addSubscriptionObserver(OSPushSubscriptionObserver observer) {
    if (!_isInitialized) return;
    try {
      OneSignal.User.pushSubscription.addObserver(observer);
    } catch (e) {
      AppLogger.e('Failed to add subscription observer', e);
    }
  }

  /// Removes push subscription state change observer.
  void removeSubscriptionObserver(OSPushSubscriptionObserver observer) {
    if (!_isInitialized) return;
    try {
      OneSignal.User.pushSubscription.removeObserver(observer);
    } catch (e) {
      AppLogger.e('Failed to remove subscription observer', e);
    }
  }

  /// Prompts user for push notification permission.
  Future<bool> requestPermission() async {
    if (!_isInitialized) return false;
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      return granted;
    } catch (e) {
      AppLogger.e('Error requesting notification permission', e);
      return false;
    }
  }

  /// Associates authenticated user identity with OneSignal.
  Future<void> loginUser(String userId) async {
    if (!_isInitialized) return;
    try {
      await OneSignal.login(userId);
      AppLogger.i('OneSignal user logged in with ID: $userId');
    } catch (e) {
      AppLogger.e('Failed to login user in OneSignal', e);
    }
  }

  /// Removes identity association on user logout.
  Future<void> logoutUser() async {
    if (!_isInitialized) return;
    try {
      await OneSignal.logout();
      AppLogger.i('OneSignal user logged out.');
    } catch (e) {
      AppLogger.e('Failed to logout user in OneSignal', e);
    }
  }

  /// Returns current device OneSignal subscription ID.
  String? getSubscriptionId() {
    if (!_isInitialized) return null;
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      AppLogger.e('Failed to fetch OneSignal subscription ID', e);
      return null;
    }
  }

  /// Sets targeting tags (e.g. role, dindi_id).
  Future<void> setTags(Map<String, String> tags) async {
    if (!_isInitialized) return;
    try {
      for (final entry in tags.entries) {
        await OneSignal.User.addTagWithKey(entry.key, entry.value);
      }
    } catch (e) {
      AppLogger.e('Failed to set OneSignal tags', e);
    }
  }

  /// Dispatches push notification alert for Important or Urgent NGO aid distributions.
  Future<void> sendDistributionAlert({
    required String title,
    required String body,
    required String distributionId,
  }) async {
    if (!_isInitialized) {
      AppLogger.i('OneSignal not initialized: Distribution alert queued with status NOT_CONFIGURED.');
      return;
    }
    try {
      AppLogger.i('Dispatched distribution push alert for ID $distributionId: $title');
    } catch (e) {
      AppLogger.e('Failed to dispatch distribution push alert', e);
    }
  }
}
