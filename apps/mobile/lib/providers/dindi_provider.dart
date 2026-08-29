import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/dindi_repository.dart';
import '../services/mock_dindi_data.dart';

/// Centralized state provider for Dindi membership, itinerary micro-schedule, and passes.
class DindiProvider extends ChangeNotifier {
  final DindiRepository _repository;

  DindiProvider({required DindiRepository repository}) : _repository = repository;

  List<Dindi> _dindis = [];
  Dindi? _currentDindi;
  DindiMember? _currentMembership;
  DindiPass? _currentPass;
  List<DindiScheduleItem> _scheduleItems = [];

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isFromMock = true;

  DindiCapabilities _capabilities = const DindiCapabilities();

  // Getters
  List<Dindi> get dindis => UnmodifiableListView(_dindis);
  Dindi? get currentDindi => _currentDindi;
  DindiMember? get currentMembership => _currentMembership;
  DindiPass? get currentPass => _currentPass;
  bool get hasJoinedDindi => _currentDindi != null && _currentMembership != null;

  List<DindiScheduleItem> get scheduleItems => UnmodifiableListView(_scheduleItems);

  DindiScheduleItem? get currentScheduleItem {
    return _scheduleItems.firstWhere(
      (item) => item.isCurrent,
      orElse: () => _scheduleItems.isNotEmpty ? _scheduleItems.first : MockDindiData.getScheduleForDindi('demo').first,
    );
  }

  DindiScheduleItem? get nextScheduleItem {
    final upcoming = _scheduleItems.where((item) => item.isUpcoming).toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    return null;
  }

  List<DindiScheduleItem> get completedItems => _scheduleItems.where((item) => item.isCompleted).toList();
  List<DindiScheduleItem> get upcomingItems => _scheduleItems.where((item) => item.isUpcoming).toList();

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isFromMock => _isFromMock;
  DindiCapabilities get capabilities => _capabilities;

  /// Loads available Dindis along the Wari route.
  Future<void> loadDindis() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _dindis = await _repository.fetchDindis();
      _isFromMock = true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load Dindis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects active Dindi view and fetches its micro-schedule.
  Future<void> selectDindi(String dindiId) async {
    _currentDindi = _dindis.firstWhere(
      (d) => d.id == dindiId,
      orElse: () => _dindis.isNotEmpty ? _dindis.first : MockDindiData.dindis.first,
    );
    await loadSchedule(dindiId);
  }

  /// Loads schedule for the specified Dindi ID.
  Future<void> loadSchedule(String dindiId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _scheduleItems = await _repository.fetchDindiSchedule(dindiId);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load schedule: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Joins user to the selected Dindi and issues Digital Dindi Pass.
  Future<bool> joinDindi(String dindiId, String userId, {String userName = 'Varkari Pilgrim'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dindi = _dindis.firstWhere((d) => d.id == dindiId, orElse: () => MockDindiData.dindis.first);
      _currentDindi = dindi;
      _currentMembership = await _repository.joinDindi(dindiId, userId, userName: userName);
      _currentPass = await _repository.getDindiPass(dindiId, userId, dindi.name);
      await loadSchedule(dindiId);
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not complete Dindi registration: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Leaves current Dindi.
  void leaveDindi() {
    _currentDindi = null;
    _currentMembership = null;
    _currentPass = null;
    _scheduleItems = [];
    notifyListeners();
  }

  /// Configures capability flags for role checks.
  void setCapabilities(DindiCapabilities caps) {
    _capabilities = caps;
    notifyListeners();
  }
}
