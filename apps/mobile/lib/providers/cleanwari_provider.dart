import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/cleanwari_repository.dart';
import '../services/cleanwari_dispatch_service.dart';
import '../services/sanitation_priority_engine.dart';

/// Provider managing CleanWari reporting workflows, cleaner task feed, and duplicate protection.
/// Real-time powered directly by Cloud Firestore `sanitation_reports` collection.
class CleanWariProvider extends ChangeNotifier {
  final CleanWariRepository _repository;
  StreamSubscription<List<CleanlinessReport>>? _reportsSubscription;

  CleanWariProvider({required CleanWariRepository repository}) : _repository = repository {
    _subscribeRealtimeReports();
  }

  List<CleanlinessReport> _reports = [];
  List<CleanlinessReport> _cleanerTasks = [];
  CleanlinessReport? _activeReport;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDuplicateNotice = false;
  String? _errorMessage;

  List<CleanlinessReport> get reports => List.unmodifiable(_reports);
  List<CleanlinessReport> get cleanerTasks => List.unmodifiable(_cleanerTasks);
  CleanlinessReport? get activeReport => _activeReport;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isDuplicateNotice => _isDuplicateNotice;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeRealtimeReports() {
    _reportsSubscription?.cancel();
    _reportsSubscription = _repository.streamReports().listen((list) {
      _reports = list;
      _cleanerTasks = list;
      if (_activeReport != null) {
        final updatedIndex = list.indexWhere((r) => r.id == _activeReport!.id);
        if (updatedIndex != -1) {
          _activeReport = list[updatedIndex];
        }
      }
      notifyListeners();
    }, onError: (err) {
      _hasError = true;
      _errorMessage = 'Unable to stream sanitation reports: $err';
      notifyListeners();
    });
  }

  Future<void> loadReports() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _reports = await _repository.fetchReports();
      _cleanerTasks = _reports;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Unable to load reports: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCleanerTasks(String cleanerId) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final all = await _repository.fetchCleanerTasks(cleanerId);
      _cleanerTasks = all;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Unable to load cleaner tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a new cleanliness report with duplicate detection guard.
  Future<CleanlinessReport?> submitReport({
    required String toiletId,
    required String toiletQrCode,
    required String toiletName,
    required String reporterId,
    String reporterRole = 'VARKARI',
    double? latitude,
    double? longitude,
    required CleanlinessIssueType issueType,
    required String description,
  }) async {
    _isDuplicateNotice = false;
    if (CleanWariDispatchService.isDuplicateReport(_reports, toiletId, issueType)) {
      _isDuplicateNotice = true;
      notifyListeners();
      return _reports.firstWhere((r) => r.toiletId == toiletId && r.issueType == issueType);
    }

    final priority = SanitationPriorityEngine.calculatePriority(
      issueType: issueType,
      description: description,
      nearbyUnresolvedCount: _reports.where((r) => r.status != CleanlinessReportStatus.RESOLVED).length,
    );

    final report = CleanlinessReport(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      toiletId: toiletId,
      toiletQrCode: toiletQrCode,
      toiletName: toiletName,
      reporterId: reporterId,
      reporterRole: reporterRole,
      latitude: latitude ?? 18.5204,
      longitude: longitude ?? 73.8567,
      issueType: issueType,
      description: description,
      reportedAt: DateTime.now(),
      status: CleanlinessReportStatus.REPORTED,
      priority: priority,
      isDemo: false,
    );

    final submitted = await _repository.submitReport(report);
    _activeReport = submitted;
    return submitted;
  }

  Future<void> acceptTask(String reportId) async {
    final updated = await _repository.updateReportStatus(reportId, CleanlinessReportStatus.ACCEPTED);
    if (updated != null) {
      _activeReport = updated;
      notifyListeners();
    }
  }

  Future<void> markEnRoute(String reportId) async {
    final updated = await _repository.updateReportStatus(reportId, CleanlinessReportStatus.IN_PROGRESS);
    if (updated != null) {
      _activeReport = updated;
      notifyListeners();
    }
  }

  Future<void> startCleaning(String reportId) async {
    final updated = await _repository.updateReportStatus(reportId, CleanlinessReportStatus.IN_PROGRESS);
    if (updated != null) {
      _activeReport = updated;
      notifyListeners();
    }
  }

  Future<void> resolveTask(String reportId, String resolutionNote) async {
    final updated = await _repository.updateReportStatus(
      reportId,
      CleanlinessReportStatus.RESOLVED,
      resolutionNote: resolutionNote,
    );
    if (updated != null) {
      _activeReport = updated;
      notifyListeners();
    }
  }
}
