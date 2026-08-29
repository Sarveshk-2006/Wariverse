import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

/// Connection states for real-time WebSocket infrastructure.
enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  authFailure,
  serverError,
}

/// Centralized event router & WebSocket connection manager for WariVerse AI.
class WebSocketService {
  WebSocketService._internal();
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocket? _socket;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  String? _authToken;
  String _clientId = 'client-${DateTime.now().millisecondsSinceEpoch}';

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectBackoffSeconds = 30;

  final StreamController<RealtimeConnectionState> _stateController =
      StreamController<RealtimeConnectionState>.broadcast();

  final Map<String, List<Function(Map<String, dynamic>)>> _eventListeners = {};

  RealtimeConnectionState get state => _state;
  Stream<RealtimeConnectionState> get stateStream => _stateController.stream;

  void setAuthToken(String? token) => _authToken = token;

  /// Connects to central WebSocket server.
  Future<void> connect({String? clientId}) async {
    if (clientId != null) _clientId = clientId;

    if (_state == RealtimeConnectionState.connected || _state == RealtimeConnectionState.connecting) {
      return;
    }

    _updateState(RealtimeConnectionState.connecting);

    final wsBase = EnvConfig.websocketUrl;
    final Uri uri = Uri.parse('$wsBase/$_clientId${_authToken != null ? '?token=$_authToken' : ''}');

    try {
      _socket = await WebSocket.connect(uri.toString()).timeout(
        const Duration(seconds: EnvConfig.connectTimeoutSeconds),
      );

      _updateState(RealtimeConnectionState.connected);
      _reconnectAttempts = 0;
      AppLogger.i('WebSocket connected: $_clientId');

      _startHeartbeat();

      _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      AppLogger.e('WebSocket connection failed', e);
      _updateState(RealtimeConnectionState.serverError);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic rawData) {
    try {
      if (rawData is String) {
        final Map<String, dynamic> msg = jsonDecode(rawData);
        final String eventType = msg['type'] as String? ?? 'UNKNOWN';
        final Map<String, dynamic> data = (msg['data'] as Map<String, dynamic>?) ?? {};

        _dispatchEvent(eventType, data);
      }
    } catch (e) {
      AppLogger.e('Error decoding WebSocket event', e);
    }
  }

  void _dispatchEvent(String eventType, Map<String, dynamic> data) {
    final listeners = _eventListeners[eventType];
    if (listeners != null && listeners.isNotEmpty) {
      for (final callback in List.from(listeners)) {
        try {
          callback(data);
        } catch (e) {
          AppLogger.e('Error in event listener callback for $eventType', e);
        }
      }
    }
  }

  /// Subscribes to real-time events (`NEW_SOS`, `DINDI_LOCATION_UPDATED`, etc.)
  void subscribe(String eventType, Function(Map<String, dynamic>) callback) {
    _eventListeners.putIfAbsent(eventType, () => []);
    if (!_eventListeners[eventType]!.contains(callback)) {
      _eventListeners[eventType]!.add(callback);
    }
  }

  /// Unsubscribes from events.
  void unsubscribe(String eventType, Function(Map<String, dynamic>) callback) {
    _eventListeners[eventType]?.remove(callback);
  }

  /// Sends a client message to backend.
  void send(String type, Map<String, dynamic> payload) {
    if (_state == RealtimeConnectionState.connected && _socket != null) {
      final msg = jsonEncode({'type': type, 'data': payload});
      _socket!.add(msg);
    } else {
      AppLogger.d('Cannot send message: WebSocket not connected.');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_state == RealtimeConnectionState.connected) {
        send('PING', {'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    _updateState(RealtimeConnectionState.reconnecting);

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, _maxReconnectBackoffSeconds);
    AppLogger.i('Scheduling WebSocket reconnect attempt #$_reconnectAttempts in ${delaySeconds}s');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  void _onError(dynamic error) {
    AppLogger.e('WebSocket stream error', error);
    _updateState(RealtimeConnectionState.serverError);
    _scheduleReconnect();
  }

  void _onDone() {
    AppLogger.i('WebSocket connection closed.');
    if (_state != RealtimeConnectionState.disconnected) {
      _scheduleReconnect();
    }
  }

  void _updateState(RealtimeConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Cleanly closes connection and releases resources.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectAttempts = 0;

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    _updateState(RealtimeConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _eventListeners.clear();
  }
}
