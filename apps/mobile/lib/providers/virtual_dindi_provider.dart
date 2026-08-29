// ignore_for_file: constant_identifier_names, unused_field
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/virtual_dindi_model.dart';
import '../repositories/virtual_dindi_repository.dart';
import '../services/virtual_dindi_local_service.dart';
import '../services/dindi_notification_service.dart';
import '../core/utils/virtual_dindi_engine.dart';

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
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Getters
  VirtualDindi? get activeDindi => _activeDindi;
  bool get hasActiveDindi => _activeDindi != null;
  List<VirtualDindiMember> get members => List.unmodifiable(_members);
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

    // Calculate Robust Geographic Center
    _groupCenter = VirtualDindiEngine.calculateRobustGroupCenter(_members);
    VirtualDindiLocalService.saveGroupCenter(_groupCenter!.latitude, _groupCenter!.longitude);

    if (_currentUserUid != null && _activeDindi != null) {
      final me = _members.firstWhere(
        (m) => m.uid == _currentUserUid,
        orElse: () => _members.first,
      );

      final eval = VirtualDindiEngine.evaluateMemberSeparation(
        memberLat: me.lastLatitude,
        memberLng: me.lastLongitude,
        accuracyMeters: me.accuracyMeters,
        groupCenterLat: _groupCenter!.latitude,
        groupCenterLng: _groupCenter!.longitude,
        currentPreviousState: _currentSeparationState,
        stateEnteredAt: _stateEnteredAt,
        previousDistanceMeters: _previousDistanceMeters,
        safeRadius: _activeDindi!.safeRadiusMeters,
        cautionThreshold: _activeDindi!.separationThresholdMeters,
        criticalThreshold: _activeDindi!.criticalThresholdMeters,
      );

      _previousDistanceMeters = _distanceFromGroupMeters;
      _distanceFromGroupMeters = eval.rawDistanceMeters;
      _currentTrend = eval.trend;

      if (eval.stateChanged) {
        _currentSeparationState = eval.separationState;
        _stateEnteredAt = DateTime.now();

        // Trigger local notification alert with cooldown
        _notificationService.triggerSeparationAlert(
          state: _currentSeparationState,
          distanceMeters: _distanceFromGroupMeters,
          dindiName: _activeDindi!.name,
          trend: _currentTrend,
        );

        // Log Firestore separation event on escalation
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

      // Update Firestore member record
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

  /// Leader Controls: Send Broadcast Message to Members
  Future<void> sendLeaderBroadcast(String message) async {
    if (_activeDindi == null || _currentUserUid == null) return;
    await _repository.logEvent(
      dindiId: _activeDindi!.dindiId,
      type: VirtualDindiEventType.BROADCAST_SENT,
      actorUid: _currentUserUid!,
      targetUid: _activeDindi!.dindiId,
      details: 'Leader Broadcast: "$message"',
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
    _positionSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
