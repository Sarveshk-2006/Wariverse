import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/cleanwari_repository.dart';
import '../services/cleanwari_dispatch_service.dart';

/// Provider managing CleanWari reporting workflows, cleaner task feed, and duplicate protection.
class CleanWariProvider extends ChangeNotifier {
  final CleanWariRepository _repository;

  CleanWariProvider({required CleanWariRepository repository}) : _repository = repository;

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

  Future<void> loadReports() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _reports = await _repository.fetchReports();
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
      _cleanerTasks = await _repository.fetchCleanerTasks(cleanerId);
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
    required CleanlinessIssueType issueType,
    required String description,
  }) async {
    _isDuplicateNotice = false;
    if (CleanWariDispatchService.isDuplicateReport(_reports, toiletId, issueType)) {
      _isDuplicateNotice = true;
      notifyListeners();
      return _reports.firstWhere((r) => r.toiletId == toiletId && r.issueType == issueType);
    }

    final priority = CleanWariDispatchService.calculatePriority(issueType);
    final report = CleanlinessReport(
      id: 'rep-${DateTime.now().millisecondsSinceEpoch}',
      toiletId: toiletId,
      toiletQrCode: toiletQrCode,
      toiletName: toiletName,
      reporterId: reporterId,
      issueType: issueType,
      description: description,
      reportedAt: DateTime.now(),
      status: CleanlinessReportStatus.REPORTED,
      priority: priority,
      isDemo: true,
    );

    final submitted = await _repository.submitReport(report);
    _activeReport = submitted;
    await loadReports();
    return submitted;
  }

  Future<void> acceptTask(String reportId) async {
    final updated = await _repository.updateReportStatus(reportId, CleanlinessReportStatus.ACCEPTED);
    if (updated != null) {
      _activeReport = updated;
      await loadReports();
    }
  }

  Future<void> startCleaning(String reportId) async {
    final updated = await _repository.updateReportStatus(reportId, CleanlinessReportStatus.IN_PROGRESS);
    if (updated != null) {
      _activeReport = updated;
      await loadReports();
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
      await loadReports();
    }
  }

  Future<void> unableToComplete(String reportId, String reason) async {
    final updated = await _repository.updateReportStatus(
      reportId,
      CleanlinessReportStatus.UNABLE_TO_COMPLETE,
      resolutionNote: reason,
    );
    if (updated != null) {
      _activeReport = updated;
      await loadReports();
    }
  }
}
