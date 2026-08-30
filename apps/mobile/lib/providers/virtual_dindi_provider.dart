import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/virtual_dindi_model.dart';
import '../models/dindi_community_post.dart';
import '../repositories/virtual_dindi_repository.dart';
import '../services/virtual_dindi_local_service.dart';
import '../services/dindi_notification_service.dart';
import '../core/utils/virtual_dindi_engine.dart';
import '../core/utils/app_logger.dart';

enum DindiNetworkStatus {
  LIVE,
  SYNCING,
  OFFLINE,
}

/// Centralized Provider managing Virtual Dindi, Separation Engine, and Sync Engine.
class VirtualDindiProvider with ChangeNotifier {
  final VirtualDindiRepository _repository;
  final DindiNotificationService _notificationService = DindiNotificationService();

  VirtualDindiProvider({VirtualDindiRepository? repository})
      : _repository = repository ?? VirtualDindiRepository() {
    _initConnectivityListener();
    _loadCachedState();
  }

  VirtualDindi? _activeDindi;
  List<VirtualDindiMember> _members = [];
  List<DindiBroadcast> _broadcasts = [];
  GroupCenterResult? _groupCenter;
  
  SeparationState _currentSeparationState = SeparationState.SAFE;
  MovementTrend _currentTrend = MovementTrend.STABLE_SEPARATION;
  double _distanceFromGroupMeters = 0.0;
  double _previousDistanceMeters = 0.0;
  DateTime _stateEnteredAt = DateTime.now();

  DindiNetworkStatus _networkStatus = DindiNetworkStatus.LIVE;
  DateTime _lastSyncedAt = DateTime.now();

  StreamSubscription<VirtualDindi?>? _dindiSubscription;
  StreamSubscription<List<VirtualDindiMember>>? _membersSubscription;
  StreamSubscription<List<DindiBroadcast>>? _broadcastsSubscription;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  VirtualDindi? get activeDindi => _activeDindi;
  bool get hasActiveDindi => _activeDindi != null;
  List<VirtualDindiMember> get members => List.unmodifiable(_members);
  List<DindiBroadcast> get broadcasts => List.unmodifiable(_broadcasts);
  GroupCenterResult? get groupCenter => _groupCenter;

  List<VirtualDindiMember> get separatedMembers => _members.where((m) =>
    m.separationState == SeparationState.SEPARATED || m.separationState == SeparationState.CRITICAL
  ).toList();
  List<VirtualDindiMember> get cautionMembers => _members.where((m) => m.separationState == SeparationState.CAUTION).toList();
  List<VirtualDindiMember> get safeMembers => _members.where((m) => m.separationState == SeparationState.SAFE).toList();
  bool get hasSeparationAlert => separatedMembers.isNotEmpty;

  SeparationState get currentSeparationState => _currentSeparationState;
  MovementTrend get currentTrend => _currentTrend;
  double get distanceFromGroupMeters => _distanceFromGroupMeters;
  DindiNetworkStatus get networkStatus => _networkStatus;
  DateTime get lastSyncedAt => _lastSyncedAt;

  bool get isLeader => _activeDindi != null && _currentUserUid != null && _activeDindi!.leaderUid == _currentUserUid;
  String? _currentUserUid;
  String? _currentDisplayName;
  String? _currentRole;

  void setCurrentUser({required String uid, required String displayName, required String role}) {
    _currentUserUid = uid;
    _currentDisplayName = displayName;
    _currentRole = role;
  }

  Future<void> _loadCachedState() async {
    final cached = await VirtualDindiLocalService.getActiveDindi();
    if (cached != null) {
      _activeDindi = cached;
      _members = await VirtualDindiLocalService.getMembers();
      final centerMap = await VirtualDindiLocalService.getGroupCenter();
      if (centerMap != null) {
        _groupCenter = GroupCenterResult(
          latitude: (centerMap['lat'] as num).toDouble(),
          longitude: (centerMap['lng'] as num).toDouble(),
          activeContributingMembers: _members.length,
          isReliable: true,
        );
      }
      _subscribeToStreams(cached.dindiId);
      _startGpsLocationTracking();
      notifyListeners();
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        _networkStatus = DindiNetworkStatus.OFFLINE;
        notifyListeners();
      } else {
        _networkStatus = DindiNetworkStatus.SYNCING;
        notifyListeners();
        await _repository.syncQueuedOfflineEvents();
        _networkStatus = DindiNetworkStatus.LIVE;
        _lastSyncedAt = DateTime.now();
        notifyListeners();
      }
    });
  }

  /// Create Virtual Dindi.
  Future<VirtualDindi> createVirtualDindi({
    required String name,
    required String description,
    required String leaderUid,
    required String leaderName,
    required double meetingPointLat,
    required double meetingPointLng,
    required String meetingPointName,
    double safeRadiusMeters = 75.0,
    double separationThresholdMeters = 150.0,
    double criticalThresholdMeters = 300.0,
  }) async {
    _currentUserUid = leaderUid;
    _currentDisplayName = leaderName;
    _currentRole = 'DINDI_LEADER';

    final dindi = await _repository.createVirtualDindi(
      name: name,
      description: description,
      leaderUid: leaderUid,
      leaderName: leaderName,
      meetingPointLat: meetingPointLat,
      meetingPointLng: meetingPointLng,
      meetingPointName: meetingPointName,
      safeRadiusMeters: safeRadiusMeters,
      separationThresholdMeters: separationThresholdMeters,
      criticalThresholdMeters: criticalThresholdMeters,
    );

    _activeDindi = dindi;
    _subscribeToStreams(dindi.dindiId);
    _startGpsLocationTracking();
    notifyListeners();
    return dindi;
  }

  /// Join Virtual Dindi via code or QR.
  Future<VirtualDindi?> joinVirtualDindi({
    required String codeOrId,
    required String uid,
    required String displayName,
    required String role,
    required double currentLat,
    required double currentLng,
  }) async {
    _currentUserUid = uid;
    _currentDisplayName = displayName;
    _currentRole = role;

    final dindi = await _repository.joinVirtualDindi(
      codeOrId: codeOrId,
      uid: uid,
      displayName: displayName,
      role: role,
      currentLat: currentLat,
      currentLng: currentLng,
    );

    if (dindi != null) {
      _activeDindi = dindi;
      _subscribeToStreams(dindi.dindiId);
      _startGpsLocationTracking();
      notifyListeners();
    }
    return dindi;
  }

  /// Leave current Virtual Dindi.
  Future<void> leaveVirtualDindi() async {
    if (_activeDindi != null && _currentUserUid != null) {
      await _repository.leaveVirtualDindi(
        dindiId: _activeDindi!.dindiId,
        uid: _currentUserUid!,
        displayName: _currentDisplayName ?? 'Varkari Pilgrim',
      );
    }

    _cancelSubscriptions();
    _activeDindi = null;
    _members = [];
    _groupCenter = null;
    _currentSeparationState = SeparationState.SAFE;
    _distanceFromGroupMeters = 0.0;
    await VirtualDindiLocalService.clearActiveDindi();
    notifyListeners();
  }

  void _subscribeToStreams(String dindiId) {
    _cancelSubscriptions();

    _dindiSubscription = _repository.streamDindi(dindiId).listen((updated) {
      if (updated != null) {
        _activeDindi = updated;
        _lastSyncedAt = DateTime.now();
        VirtualDindiLocalService.saveActiveDindi(updated);
        notifyListeners();
      }
    });

    _membersSubscription = _repository.streamMembers(dindiId).listen((memberList) {
      _members = memberList;
      _recalculateGroupCenterAndSeparation();
      VirtualDindiLocalService.saveMembers(memberList);
      notifyListeners();
    });

    _broadcastsSubscription = _repository.streamBroadcasts(dindiId).listen((bList) {
      _broadcasts = bList;
      notifyListeners();
    });
  }

  /// Send/publish a Dindi Leader announcement or audio broadcast to Cloud Firestore.
  Future<void> sendLeaderBroadcast({
    required String title,
    required String message,
    String type = 'ANNOUNCEMENT',
    String? audioUrl,
    String priority = 'HIGH',
  }) async {
    if (_activeDindi == null) return;

    final broadcast = DindiBroadcast(
      id: 'bc_${DateTime.now().millisecondsSinceEpoch}',
      dindiId: _activeDindi!.dindiId,
      dindiCode: _activeDindi!.joinCode,
      senderUid: _currentUserUid,
      sender: _currentDisplayName ?? _activeDindi!.leaderName,
      senderRole: 'LEADER',
      type: type,
      title: title,
      message: message,
      audioUrl: audioUrl,
      createdAt: DateTime.now(),
      priority: priority,
      isActive: true,
    );

    await _repository.sendBroadcast(
      dindiId: _activeDindi!.dindiId,
      broadcast: broadcast,
    );
  }

  void _startGpsLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _onPositionUpdated(position);
    });
  }

  void _onPositionUpdated(Position pos) {
    if (_activeDindi == null) return;

    // Update current user's local location in member list
    if (_currentUserUid != null) {
      final index = _members.indexWhere((m) => m.uid == _currentUserUid);
      if (index >= 0) {
        _members[index] = _members[index].copyWith(
          lastLatitude: pos.latitude,
          lastLongitude: pos.longitude,
          accuracyMeters: pos.accuracy,
          lastLocationAt: DateTime.now().toIso8601String(),
        );
      }
    }

    _recalculateGroupCenterAndSeparation(currentPosition: pos);
  }

  void _recalculateGroupCenterAndSeparation({Position? currentPosition}) {
    if (_members.isEmpty) return;

    final fallbackLat = _activeDindi?.meetingPointLat ?? 18.5204;
    final fallbackLng = _activeDindi?.meetingPointLng ?? 73.8567;

    // Calculate Robust Geographic Center
    _groupCenter = VirtualDindiEngine.calculateRobustGroupCenter(
      _members,
      fallbackLat: fallbackLat,
      fallbackLng: fallbackLng,
    );
    VirtualDindiLocalService.saveGroupCenter(_groupCenter!.latitude, _groupCenter!.longitude);

    final refLat = _groupCenter!.latitude;
    final refLng = _groupCenter!.longitude;

    // Recalculate distance and separation for EVERY member in the Dindi roster
    for (int i = 0; i < _members.length; i++) {
      final m = _members[i];
      final rawDist = VirtualDindiEngine.haversineDistance(
        m.lastLatitude,
        m.lastLongitude,
        refLat,
        refLng,
      );

      final eval = VirtualDindiEngine.evaluateMemberSeparation(
        memberLat: m.lastLatitude,
        memberLng: m.lastLongitude,
        accuracyMeters: m.accuracyMeters,
        groupCenterLat: refLat,
        groupCenterLng: refLng,
        currentPreviousState: m.separationState,
        stateEnteredAt: DateTime.now(),
        previousDistanceMeters: m.distanceFromGroupMeters,
        safeRadius: _activeDindi?.safeRadiusMeters ?? 75.0,
        cautionThreshold: _activeDindi?.separationThresholdMeters ?? 150.0,
        criticalThreshold: _activeDindi?.criticalThresholdMeters ?? 300.0,
      );

      _members[i] = m.copyWith(
        distanceFromGroupMeters: rawDist,
        separationState: eval.separationState,
        trend: eval.trend,
        isInsideDindi: eval.separationState == SeparationState.SAFE,
      );

      AppLogger.d('DINDI LOCATION DEBUG: member=${m.displayName} (${m.lastLatitude}, ${m.lastLongitude}) ref=($refLat, $refLng) distance=${rawDist.toStringAsFixed(1)}m status=${eval.separationState.name}');
    }

    if (_currentUserUid != null && _activeDindi != null) {
      final meIndex = _members.indexWhere((m) => m.uid == _currentUserUid);
      final me = meIndex >= 0 ? _members[meIndex] : _members.first;

      _previousDistanceMeters = _distanceFromGroupMeters;
      _distanceFromGroupMeters = me.distanceFromGroupMeters;
      _currentTrend = me.trend;

      if (_currentSeparationState != me.separationState) {
        _currentSeparationState = me.separationState;
        _stateEnteredAt = DateTime.now();

        _notificationService.triggerSeparationAlert(
          state: _currentSeparationState,
          distanceMeters: _distanceFromGroupMeters,
          dindiName: _activeDindi!.name,
          trend: _currentTrend,
        );

        if (_currentSeparationState == SeparationState.SEPARATED || _currentSeparationState == SeparationState.CRITICAL) {
          _repository.logEvent(
            dindiId: _activeDindi!.dindiId,
            type: _currentSeparationState == SeparationState.CRITICAL
                ? VirtualDindiEventType.MEMBER_CRITICAL_SEPARATION
                : VirtualDindiEventType.MEMBER_SEPARATED,
            actorUid: me.uid,
            targetUid: me.uid,
            details: '${me.displayName} separation state: ${_currentSeparationState.name} (${_distanceFromGroupMeters.toInt()}m)',
            latitude: me.lastLatitude,
            longitude: me.lastLongitude,
            distanceMeters: _distanceFromGroupMeters,
          );
        }
      }

      _repository.updateMemberState(
        dindiId: _activeDindi!.dindiId,
        uid: me.uid,
        lat: me.lastLatitude,
        lng: me.lastLongitude,
        accuracy: me.accuracyMeters,
        distanceFromGroup: _distanceFromGroupMeters,
        separationState: _currentSeparationState,
        trend: _currentTrend,
      );
    }

    notifyListeners();
  }

  /// Leader Controls: Start, Pause, End Dindi
  Future<void> setDindiStatus(VirtualDindiStatus status) async {
    if (_activeDindi == null || _currentUserUid == null) return;
    await _repository.updateDindiStatus(_activeDindi!.dindiId, status, _currentUserUid!);
  }

  /// Leader Controls: Update Reunification Point
  Future<void> setReunificationPoint({required double lat, required double lng, required String name}) async {
    if (_activeDindi == null || _currentUserUid == null) return;
    await _repository.updateMeetingPoint(
      dindiId: _activeDindi!.dindiId,
      leaderUid: _currentUserUid!,
      lat: lat,
      lng: lng,
      name: name,
    );
  }

  /// Leader Controls: Remove a member from the Virtual Dindi.
  Future<void> removeMember(String targetUid) async {
    if (_activeDindi == null || _currentUserUid == null || !isLeader) return;
    await _repository.removeMember(
      dindiId: _activeDindi!.dindiId,
      targetUid: targetUid,
      leaderUid: _currentUserUid!,
    );
  }

  void _cancelSubscriptions() {
    _dindiSubscription?.cancel();
    _membersSubscription?.cancel();
    _broadcastsSubscription?.cancel();
    _positionSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
