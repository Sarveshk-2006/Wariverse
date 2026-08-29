import 'dart:async';
import '../core/network/realtime_connection_state.dart';
import '../core/utils/app_logger.dart';

/// Abstract realtime event stream service interface.
abstract class RealtimeService {
  RealtimeConnectionState get connectionState;
  Stream<RealtimeConnectionState> get connectionStateStream;
  
  void subscribeToDocument(String path, void Function(Map<String, dynamic> data) onData);
  void subscribeToCollection(String path, void Function(List<Map<String, dynamic>> items) onData);
  void unsubscribe(String path);
  void dispose();
}

/// Firestore realtime service implementation wrapper.
class FirestoreRealtimeService implements RealtimeService {
  static final FirestoreRealtimeService _instance = FirestoreRealtimeService._internal();
  factory FirestoreRealtimeService() => _instance;
  FirestoreRealtimeService._internal();

  RealtimeConnectionState _connectionState = RealtimeConnectionState.live;
  final _connectionStateController = StreamController<RealtimeConnectionState>.broadcast();
  final Map<String, StreamSubscription> _subscriptions = {};

  @override
  RealtimeConnectionState get connectionState => _connectionState;

  @override
  Stream<RealtimeConnectionState> get connectionStateStream => _connectionStateController.stream;

  void updateConnectionState(RealtimeConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      AppLogger.i('RealtimeService connection state changed: ${newState.label}');
    }
  }

  @override
  void subscribeToDocument(String path, void Function(Map<String, dynamic> data) onData) {
    AppLogger.i('Subscribing to realtime document: $path');
  }

  @override
  void subscribeToCollection(String path, void Function(List<Map<String, dynamic>> items) onData) {
    AppLogger.i('Subscribing to realtime collection: $path');
  }

  @override
  void unsubscribe(String path) {
    if (_subscriptions.containsKey(path)) {
      _subscriptions[path]?.cancel();
      _subscriptions.remove(path);
      AppLogger.i('Unsubscribed from realtime path: $path');
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _connectionStateController.close();
  }
}
