import '../models/models_exports.dart';
import '../services/api_service.dart';
import '../services/cleanwari_dispatch_service.dart';

/// Repository managing CleanWari cleanliness reports, task dispatch, and status updates.
class CleanWariRepository {
  final ApiService _apiService;
  final List<CleanlinessReport> _localReports = [];

  CleanWariRepository(this._apiService) {
    _initMockReports();
  }

  void _initMockReports() {
    _localReports.addAll([
      CleanlinessReport(
        id: 'rep-001',
        toiletId: 'toilet-001',
        toiletQrCode: 'cleanwari:toilet:toilet-001',
        toiletName: 'Pandharpur Route — Halt 03',
        reporterId: 'varkari-10',
        issueType: CleanlinessIssueType.OVERFLOW,
        description: 'Water overflow near entrance gate.',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: CleanlinessReportStatus.IN_PROGRESS,
        priority: CleanlinessReportPriority.HIGH,
        assignedCleanerId: 'cleaner-01',
        assignedCleanerName: 'Ramesh Pawar',
        isDemo: true,
      ),
      CleanlinessReport(
        id: 'rep-002',
        toiletId: 'toilet-002',
        toiletQrCode: 'cleanwari:toilet:toilet-002',
        toiletName: 'Hadapsar Seva Pandal #5',
        reporterId: 'varkari-12',
        issueType: CleanlinessIssueType.NO_WATER,
        description: 'Main water tank empty.',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 35)),
        status: CleanlinessReportStatus.ASSIGNED,
        priority: CleanlinessReportPriority.HIGH,
        assignedCleanerId: 'cleaner-01',
        assignedCleanerName: 'Ramesh Pawar',
        isDemo: true,
      ),
      CleanlinessReport(
        id: 'rep-003',
        toiletId: 'toilet-003',
        toiletQrCode: 'cleanwari:toilet:toilet-003',
        toiletName: 'Saswad Ringan Ground Facility',
        reporterId: 'varkari-15',
        issueType: CleanlinessIssueType.NEEDS_CLEANING,
        description: 'Needs sanitation spray and sweeping.',
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: CleanlinessReportStatus.RESOLVED,
        priority: CleanlinessReportPriority.MEDIUM,
        assignedCleanerId: 'cleaner-02',
        assignedCleanerName: 'Sunil Deshmukh',
        resolvedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        resolutionNote: 'Sanitized and refilled water tank.',
        isDemo: true,
      ),
    ]);
  }

  /// Fetches all active and historical cleanliness reports.
  Future<List<CleanlinessReport>> fetchReports() async {
    try {
      final res = await _apiService.get('/toilets/reports');
      if (res is List) {
        return res.map((item) => CleanlinessReport.fromJson(item as Map<String, dynamic>)).toList();
      }
      return List.unmodifiable(_localReports);
    } catch (_) {
      return List.unmodifiable(_localReports);
    }
  }

  /// Fetches tasks assigned to a specific sanitation cleaner staff member.
  Future<List<CleanlinessReport>> fetchCleanerTasks(String cleanerId) async {
    final all = await fetchReports();
    return all.where((r) => r.assignedCleanerId == cleanerId || r.assignedCleanerId == null).toList();
  }

  /// Submits a new cleanliness report to backend or local fallback store.
  Future<CleanlinessReport> submitReport(CleanlinessReport report) async {
    try {
      await _apiService.post('/toilets/${report.toiletId}/report-dirty', {
        'issue_type': report.issueType.name,
        'description': report.description,
      });
    } catch (_) {
      // Backend fallback -> store locally
    }

    final cleaner = CleanWariDispatchService.assignCleaner(report.toiletId);
    final processed = report.copyWith(
      status: CleanlinessReportStatus.ASSIGNED,
      assignedCleanerId: cleaner.cleanerId,
      assignedCleanerName: cleaner.cleanerName,
    );

    _localReports.insert(0, processed);
    return processed;
  }

  /// Updates report status lifecycle (e.g. ACCEPTED -> IN_PROGRESS -> RESOLVED).
  Future<CleanlinessReport?> updateReportStatus(
    String reportId,
    CleanlinessReportStatus newStatus, {
    String? resolutionNote,
  }) async {
    final index = _localReports.indexWhere((r) => r.id == reportId);
    if (index == -1) return null;

    final existing = _localReports[index];
    final updated = existing.copyWith(
      status: newStatus,
      resolutionNote: resolutionNote,
      resolvedAt: newStatus == CleanlinessReportStatus.RESOLVED ? DateTime.now() : null,
    );

    _localReports[index] = updated;
    return updated;
  }
}
