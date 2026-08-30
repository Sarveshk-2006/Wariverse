// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models_exports.dart';
import '../repositories/incident_repository.dart';
import '../services/onesignal_service.dart';
import '../core/utils/app_logger.dart';

enum IncidentNetworkStatus {
  LIVE,
  SYNCING,
  OFFLINE,
}

/// Centralized Provider managing Threat / Incident Reporting, Realtime Dispatch, and Live Response Streams.
class IncidentProvider with ChangeNotifier {
  final IncidentRepository _repository;
  final OneSignalService _oneSignalService = OneSignalService();

  IncidentProvider({IncidentRepository? repository})
      : _repository = repository ?? IncidentRepository() {
    _initConnectivityListener();
  }

  ThreatIncident? _myActiveIncident;
  List<ThreatIncident> _assignedIncidents = [];
  List<ThreatIncident> _allActiveIncidents = [];
  List<AuditLog> _auditLogs = [];

  IncidentNetworkStatus _networkStatus = IncidentNetworkStatus.LIVE;
  DateTime _lastSyncedAt = DateTime.now();

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  StreamSubscription<ThreatIncident?>? _myIncidentSub;
  StreamSubscription<List<ThreatIncident>>? _assignedSub;
  StreamSubscription<List<ThreatIncident>>? _allIncidentsSub;
  StreamSubscription<List<AuditLog>>? _auditLogsSub;
  StreamSubscription<Position>? _varkariPositionSub;
  StreamSubscription<Position>? _volunteerPositionSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  String? _currentUid;
  String? _currentName;
  String? _currentRole;

  // Getters
  ThreatIncident? get myActiveIncident => _myActiveIncident;
  bool get hasMyActiveIncident => _myActiveIncident != null && _myActiveIncident!.isActive;
  List<ThreatIncident> get assignedIncidents => List.unmodifiable(_assignedIncidents);
  List<ThreatIncident> get allActiveIncidents => List.unmodifiable(_allActiveIncidents);
  List<AuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  IncidentNetworkStatus get networkStatus => _networkStatus;
  DateTime get lastSyncedAt => _lastSyncedAt;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  void setCurrentUser({required String uid, required String displayName, required String role}) {
    if (_currentUid != uid) {
      _currentUid = uid;
      _currentName = displayName;
      _currentRole = role;
      final userRole = UserRoleX.fromString(role);
      initStreamsForRole(userRole, uid);
    }
  }

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        _networkStatus = IncidentNetworkStatus.OFFLINE;
        notifyListeners();
      } else {
        _networkStatus = IncidentNetworkStatus.SYNCING;
        notifyListeners();
        _networkStatus = IncidentNetworkStatus.LIVE;
        _lastSyncedAt = DateTime.now();
        notifyListeners();
      }
    });
  }

  /// Lazy role-scoped realtime stream subscription.
  void initStreamsForRole(UserRole role, String uid) {
    _cancelSubscriptions();
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      if (role == UserRole.VARKARI) {
        _myIncidentSub = _repository.streamMyActiveIncident(uid).listen(
          (inc) {
            _isLoading = false;
            _hasError = false;
            _errorMessage = null;
            _myActiveIncident = inc;
            if (inc != null && inc.isActive) {
              _startVarkariLocationTracking(inc.incidentId);
            } else {
              _stopVarkariLocationTracking();
            }
            notifyListeners();
          },
          onError: (err) {
            AppLogger.e('Error loading Varkari incident stream', err);
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Live incident updates unavailable';
            notifyListeners();
          },
        );
      } else if (role == UserRole.VOLUNTEER ||
                 role == UserRole.POLICE ||
                 role == UserRole.MEDICAL_TEAM ||
                 role == UserRole.CLEANER ||
                 role == UserRole.ADMIN) {
        _assignedSub = _repository.streamAssignedIncidents(uid).listen(
          (incidents) {
            _isLoading = false;
            _hasError = false;
            _errorMessage = null;
            _assignedIncidents = incidents;
            final responding = incidents.where((i) =>
              i.status == IncidentStatus.ACCEPTED ||
              i.status == IncidentStatus.EN_ROUTE ||
              i.status == IncidentStatus.ARRIVED
            ).toList();

            if (responding.isNotEmpty) {
              _startVolunteerLocationTracking(responding.first.incidentId);
            } else {
              _stopVolunteerLocationTracking();
            }
            notifyListeners();
          },
          onError: (err) {
            AppLogger.e('Error loading assigned response stream', err);
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Live response queue unavailable';
            notifyListeners();
          },
        );

        if (role == UserRole.ADMIN || role == UserRole.POLICE || role == UserRole.MEDICAL_TEAM) {
          _allIncidentsSub = _repository.streamAllIncidents().listen(
            (incidents) {
              _isLoading = false;
              _hasError = false;
              _errorMessage = null;
              _allActiveIncidents = incidents;
              notifyListeners();
            },
            onError: (err) {
              AppLogger.e('Error loading Admin incidents stream', err);
            },
          );

          _auditLogsSub = _repository.streamAuditLogs().listen(
            (logs) {
              _auditLogs = logs;
              notifyListeners();
            },
            onError: (err) {
              AppLogger.e('Error loading Admin audit logs stream', err);
            },
          );
        }
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Live incident updates unavailable';
      notifyListeners();
    }
  }

  /// Manual Retry for stream failures.
  void retry() {
    if (_currentUid != null) {
      final role = _currentRole != null ? UserRoleX.fromString(_currentRole!) : UserRole.VARKARI;
      initStreamsForRole(role, _currentUid!);
    }
  }

  /// Create a new Threat / Incident Report.
  Future<ThreatIncident> createIncident({
    required ThreatCategory category,
    required IncidentSeverity severity,
    required String description,
    required double latitude,
    required double longitude,
    double accuracyMeters = 10.0,
    List<String> mediaUrls = const [],
    String mediaType = 'NONE',
  }) async {
    final uid = _currentUid ?? 'varkari_${DateTime.now().millisecondsSinceEpoch}';
    final name = _currentName ?? 'Varkari Pilgrim';
    final role = _currentRole ?? 'VARKARI';

    final incident = await _repository.createIncident(
      reporterUid: uid,
      reporterName: name,
      reporterRole: role,
      category: category,
      severity: severity,
      description: description,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      mediaUrls: mediaUrls,
      mediaType: mediaType,
      isOffline: _networkStatus == IncidentNetworkStatus.OFFLINE,
    );

    _myActiveIncident = incident;
    if (incident.isActive) {
      _startVarkariLocationTracking(incident.incidentId);
    }

    if (incident.assignedVolunteerUid != null) {
      _notifyAssignedVolunteer(incident);
    }

    notifyListeners();
    return incident;
  }

  /// Volunteer Accepts Assigned Incident (Transactional).
  Future<ThreatIncident> acceptIncident(String incidentId) async {
    final uid = _currentUid ?? 'vol_001';
    final name = _currentName ?? 'Palkhi Responder';

    final updated = await _repository.acceptIncident(
      incidentId: incidentId,
      volunteerUid: uid,
      volunteerName: name,
    );

    _startVolunteerLocationTracking(incidentId);
    notifyListeners();
    return updated;
  }

  /// Volunteer En Route to Varkari location.
  Future<void> setEnRoute(String incidentId) async {
    final uid = _currentUid ?? 'vol_001';
    await _repository.setEnRoute(incidentId: incidentId, volunteerUid: uid);
    notifyListeners();
  }

  /// Volunteer Marks Arrived.
  Future<void> markArrived(String incidentId) async {
    final uid = _currentUid ?? 'vol_001';
    await _repository.markArrived(incidentId: incidentId, volunteerUid: uid);
    notifyListeners();
  }

  /// Volunteer Resolves Incident.
  Future<void> resolveIncident(String incidentId, String resolutionNotes) async {
    final uid = _currentUid ?? 'vol_001';
    await _repository.resolveIncident(
      incidentId: incidentId,
      volunteerUid: uid,
      resolutionNotes: resolutionNotes,
    );
    _stopVolunteerLocationTracking();
    notifyListeners();
  }

  /// Admin Intervention: Reassign Volunteer to Incident.
  Future<void> reassignVolunteer(String incidentId, String newVolunteerUid, String newVolunteerName) async {
    final adminUid = _currentUid ?? 'admin_001';
    await _repository.reassignVolunteer(
      incidentId: incidentId,
      newVolunteerUid: newVolunteerUid,
      newVolunteerName: newVolunteerName,
      adminUid: adminUid,
    );
    notifyListeners();
  }

  /// Admin Intervention: Change Incident Priority & Severity.
  Future<void> changePriority(String incidentId, IncidentSeverity newSeverity) async {
    final adminUid = _currentUid ?? 'admin_001';
    await _repository.changePriority(
      incidentId: incidentId,
      newSeverity: newSeverity,
      adminUid: adminUid,
    );
    notifyListeners();
  }

  /// Varkari or Admin Cancels Incident.
  Future<void> cancelIncident(String incidentId) async {
    final uid = _currentUid ?? 'user_001';
    await _repository.cancelIncident(incidentId: incidentId, actorUid: uid);
    _stopVarkariLocationTracking();
    notifyListeners();
  }

  /// Battery-conscious continuous GPS tracking for Varkari during active incident.
  void _startVarkariLocationTracking(String incidentId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _varkariPositionSub?.cancel();
    _varkariPositionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _repository.updateReporterLocation(
        incidentId: incidentId,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );
    });
  }

  void _stopVarkariLocationTracking() {
    _varkariPositionSub?.cancel();
    _varkariPositionSub = null;
  }

  /// Battery-conscious continuous GPS tracking for responding Volunteer.
  void _startVolunteerLocationTracking(String incidentId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final uid = _currentUid ?? 'vol_001';

    _volunteerPositionSub?.cancel();
    _volunteerPositionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _repository.updateVolunteerLocation(
        incidentId: incidentId,
        volunteerUid: uid,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );
    });
  }

  void _stopVolunteerLocationTracking() {
    _volunteerPositionSub?.cancel();
    _volunteerPositionSub = null;
  }

  /// Sends push notification to assigned volunteer.
  void _notifyAssignedVolunteer(ThreatIncident incident) {
    if (incident.assignedVolunteerUid == null) return;
    try {
      _oneSignalService.sendDistributionAlert(
        title: '🚨 Emergency Incident Assigned',
        body: '${incident.category.displayName} (${incident.severity.name}) reported near your location. Tap to respond.',
        distributionId: incident.incidentId,
      );
    } catch (e) {
      AppLogger.e('OneSignal push notification status: NOT_CONFIGURED', e);
    }
  }

  void _cancelSubscriptions() {
    _myIncidentSub?.cancel();
    _assignedSub?.cancel();
    _allIncidentsSub?.cancel();
    _auditLogsSub?.cancel();
    _varkariPositionSub?.cancel();
    _volunteerPositionSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
