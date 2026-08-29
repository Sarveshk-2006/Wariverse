import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/sos_repository.dart';
import '../services/websocket_service.dart';
import '../services/wari_location_service.dart';
import '../services/emergency_contacts_service.dart';
import '../services/suraksha_voice_ai_service.dart';
import '../services/emergency_evidence_recording_service.dart';
import '../core/utils/idempotency_util.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

enum SosUiState {
  idle,
  confirming,
  gettingLocation,
  submitting,
  recordingEvidence,
  active,
  updatingLocation,
  offlineQueued,
  resolved,
  cancelled,
  failed,
}

/// Provider managing SOS & WoShield2 Emergency Features (2-sec hold Evidence Recording, Voice AI, SMS Alerts).
class SosProvider extends ChangeNotifier {
  final SosRepository _sosRepo;
  final WebSocketService? _wsService;
  final WariLocationService _locationService;
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final EmergencyEvidenceRecordingService _evidenceService = EmergencyEvidenceRecordingService();

  SosProvider({
    required SosRepository sosRepo,
    WebSocketService? wsService,
    WariLocationService? locationService,
  })  : _sosRepo = sosRepo,
        _wsService = wsService,
        _locationService = locationService ?? WariLocationService() {
    _initWebSocketListener();
    _checkActiveSosOnLaunch();
    _loadEmergencyContacts();
    _evidenceService.addListener(notifyListeners);
  }

  SosUiState _uiState = SosUiState.idle;
  SOSCategory _selectedCategory = SOSCategory.MEDICAL;
  String _description = '';
  final int _relayStep = 1;

  SOSIncident? _activeIncident;
  WariPosition? _currentLocation;
  List<SOSIncident> _incidents = [];
  final List<SOSIncident> _offlineQueue = [];
  List<EmergencyContact> _emergencyContacts = [];

  StreamSubscription<WariPosition>? _locationSubscription;

  bool _isLoading = false;
  bool _isFromMock = false;
  String? _errorMessage;
  String? _currentUserId;

  // Getters
  SosUiState get uiState => _uiState;
  SOSCategory get selectedCategory => _selectedCategory;
  String get description => _description;
  int get relayStep => _relayStep;

  SOSIncident? get activeIncident => _activeIncident;
  WariPosition? get currentLocation => _currentLocation;
  List<SOSIncident> get incidents => List.unmodifiable(_incidents);
  List<SOSIncident> get offlineQueue => List.unmodifiable(_offlineQueue);
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);

  bool get isLoading => _isLoading;
  bool get isFromMock => _isFromMock;
  String? get errorMessage => _errorMessage;
  bool get isRecordingEvidence => _evidenceService.isRecording;
  int get recordingProgressSeconds => _evidenceService.recordingProgressSeconds;

  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _loadEmergencyContacts();
    }
  }

  Future<void> _loadEmergencyContacts() async {
    _emergencyContacts = await _contactsService.loadContacts(userId: _currentUserId);
    notifyListeners();
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    _emergencyContacts = await _contactsService.addContact(contact, userId: _currentUserId);
    notifyListeners();
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    _emergencyContacts = await _contactsService.deleteContact(contactId, userId: _currentUserId);
    notifyListeners();
  }

  /// Triggered when user holds the SOS button for 2 seconds (WoShield2 Evidence Recording Protocol).
  Future<void> start2SecondHoldEmergencyRecording() async {
    _uiState = SosUiState.recordingEvidence;
    notifyListeners();

    await _evidenceService.start10SecondEvidenceRecording(
      onRecordingComplete: (evidenceUrl) async {
        await triggerSos(
          category: _selectedCategory,
          description: '🎥 2-SEC HOLD SOS EVIDENCE RECORDED: 10s video/audio evidence attached.',
          mediaUrl: evidenceUrl,
        );
      },
    );
  }

  /// Voice Threat AI Analysis (WoShield2 SurakshaVoiceAI).
  void analyzeVoiceThreatText(String spokenText) {
    final threatCategory = SurakshaVoiceAiService.detectThreatCategory(spokenText);
    if (threatCategory != null) {
      final category = SurakshaVoiceAiService.mapToSosCategory(threatCategory);
      final keyword = SurakshaVoiceAiService.getMatchingKeyword(spokenText);
      triggerSos(
        category: category,
        description: '🚨 VOICE THREAT AI TRIGGERED: Keyword "$keyword" detected in phrase "$spokenText"',
      );
    }
  }

  void setUiState(SosUiState state) {
    _uiState = state;
    notifyListeners();
  }

  void setSelectedCategory(SOSCategory cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void setDescription(String desc) {
    _description = desc;
    notifyListeners();
  }

  void showConfirming() {
    _uiState = SosUiState.confirming;
    notifyListeners();
  }

  void cancelConfirming() {
    _uiState = SosUiState.idle;
    notifyListeners();
  }

  void resetToIdle() {
    _stopLiveLocationTracking();
    _evidenceService.cancelRecording();
    _uiState = SosUiState.idle;
    _activeIncident = null;
    notifyListeners();
  }

  Future<void> _checkActiveSosOnLaunch() async {
    if (EnvConfig.enableMockFallback) return;
    try {
      final res = await _sosRepo.getMyActiveSos();
      if (res.incident != null) {
        _activeIncident = res.incident;
        _uiState = SosUiState.active;
        _startLiveLocationTracking();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> submitSOS() async {
    await triggerSos(
      category: _selectedCategory,
      description: _description,
    );
  }

  Future<void> triggerSos({
    required SOSCategory category,
    double? latitude,
    double? longitude,
    String? description,
    String? mediaUrl,
    String? userId,
  }) async {
    _isLoading = true;
    _uiState = SosUiState.gettingLocation;
    _errorMessage = null;
    notifyListeners();

    WariPosition pos;
    if (latitude != null && longitude != null) {
      pos = WariPosition(
        latitude: latitude,
        longitude: longitude,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        status: WariLocationStatus.liveGps,
      );
    } else {
      pos = await _locationService.getCurrentPosition();
    }

    _currentLocation = pos;
    _uiState = SosUiState.submitting;
    notifyListeners();

    final idempotencyKey = IdempotencyUtil.generateKey();

    try {
      final res = await _sosRepo.createIncident(
        category: category,
        latitude: pos.latitude != 0.0 ? pos.latitude : 18.5204,
        longitude: pos.longitude != 0.0 ? pos.longitude : 73.8567,
        accuracyMeters: pos.accuracy,
        idempotencyKey: idempotencyKey,
        description: description,
        userId: userId ?? _currentUserId,
      );
      _activeIncident = res.incident;
      _isFromMock = res.isFromMock;
      _uiState = SosUiState.active;

      // Dispatch Automated Emergency SMS Alert to Emergency Contacts with Google Maps link
      _contactsService.dispatchEmergencySmsAlert(
        contacts: _emergencyContacts,
        latitude: pos.latitude != 0.0 ? pos.latitude : 18.5204,
        longitude: pos.longitude != 0.0 ? pos.longitude : 73.8567,
        categoryName: category.displayName,
        customMessage: description,
      );

      _startLiveLocationTracking();
      await loadIncidents();
    } catch (e) {
      AppLogger.i('Network failed during SOS trigger, queuing offline with idempotency key: $idempotencyKey');
      final pendingIncident = SOSIncident(
        id: idempotencyKey,
        userId: _currentUserId ?? 'pending-offline-user',
        latitude: pos.latitude != 0.0 ? pos.latitude : 18.5204,
        longitude: pos.longitude != 0.0 ? pos.longitude : 73.8567,
        category: category,
        status: SOSStatus.CREATED,
        description: description,
        createdAt: DateTime.now(),
        isOffline: true,
      );
      _offlineQueue.add(pendingIncident);
      _uiState = SosUiState.offlineQueued;
      _errorMessage = 'SOS queued offline. Retrying connection...';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    final toRetry = List<SOSIncident>.from(_offlineQueue);
    for (final pending in toRetry) {
      try {
        final res = await _sosRepo.createIncident(
          category: pending.category,
          latitude: pending.latitude,
          longitude: pending.longitude,
          idempotencyKey: pending.id,
          description: pending.description,
        );
        _offlineQueue.removeWhere((item) => item.id == pending.id);
        _activeIncident = res.incident;
        _uiState = SosUiState.active;
        _startLiveLocationTracking();
        break;
      } catch (e) {
        AppLogger.e('Retry offline SOS failed: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void _startLiveLocationTracking() {
    _locationSubscription?.cancel();
    if (EnvConfig.enableMockFallback) return;
    _locationService.startTracking(distanceFilterMeters: 10);
    _locationSubscription = _locationService.positionStream.listen((pos) {
      _currentLocation = pos;
      if (_activeIncident != null) {
        _sosRepo.updateLiveLocation(
          sosId: _activeIncident!.id,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyMeters: pos.accuracy,
        );
      }
      notifyListeners();
    });
  }

  void _stopLiveLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
  }

  Future<void> resolveActiveSOS([String? id]) async {
    final targetId = id ?? _activeIncident?.id;
    if (targetId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _sosRepo.resolveIncident(targetId);
      if (_activeIncident?.id == targetId) {
        _activeIncident = res.incident;
        _stopLiveLocationTracking();
        _uiState = SosUiState.idle;
        _activeIncident = null;
      }
      await loadIncidents();
    } catch (e) {
      _errorMessage = 'Failed to resolve SOS: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelActiveSOS([String? id]) async {
    final targetId = id ?? _activeIncident?.id;
    if (targetId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _sosRepo.cancelIncident(targetId);
      if (_activeIncident?.id == targetId) {
        _activeIncident = res.incident;
        _stopLiveLocationTracking();
        _uiState = SosUiState.idle;
        _activeIncident = null;
      }
      await loadIncidents();
    } catch (e) {
      _errorMessage = 'Failed to cancel SOS: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadIncidents() async {
    if (EnvConfig.enableMockFallback) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _sosRepo.getIncidents();
      _incidents = res.incidents;
      _isFromMock = res.isFromMock;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initWebSocketListener() {
    _wsService?.subscribe('SOS_UPDATE', _onWebSocketSosEvent);
    _wsService?.subscribe('NEW_SOS', _onWebSocketSosEvent);
    _wsService?.subscribe('SOS_LOCATION_UPDATED', _onWebSocketLocationEvent);
  }

  void _onWebSocketSosEvent(Map<String, dynamic> data) {
    loadIncidents();
  }

  void _onWebSocketLocationEvent(Map<String, dynamic> data) {
    if (_activeIncident != null && data['sos_id'] == _activeIncident!.id) {
      AppLogger.d('Received live location update event for active SOS');
    }
  }

  @override
  void dispose() {
    _stopLiveLocationTracking();
    _evidenceService.removeListener(notifyListeners);
    _wsService?.unsubscribe('SOS_UPDATE', _onWebSocketSosEvent);
    _wsService?.unsubscribe('NEW_SOS', _onWebSocketSosEvent);
    _wsService?.unsubscribe('SOS_LOCATION_UPDATED', _onWebSocketLocationEvent);
    super.dispose();
  }
}
