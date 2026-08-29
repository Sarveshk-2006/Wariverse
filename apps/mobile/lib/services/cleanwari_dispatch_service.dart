import '../models/models_exports.dart';

/// Service responsible for priority calculation, cleaner assignment, and duplicate report checks.
class CleanWariDispatchService {
  /// Calculates task priority deterministically from issue type.
  static CleanlinessReportPriority calculatePriority(CleanlinessIssueType issueType) {
    switch (issueType) {
      case CleanlinessIssueType.NO_WATER:
      case CleanlinessIssueType.OVERFLOW:
        return CleanlinessReportPriority.HIGH;
      case CleanlinessIssueType.NEEDS_CLEANING:
      case CleanlinessIssueType.DAMAGED:
        return CleanlinessReportPriority.MEDIUM;
      case CleanlinessIssueType.OTHER:
        return CleanlinessReportPriority.LOW;
    }
  }

  /// Assigns an available sanitation staff member to the report.
  static ({String cleanerId, String cleanerName}) assignCleaner(String toiletId) {
    // Deterministic mock cleaner assignment
    if (toiletId.endsWith('1') || toiletId.endsWith('3')) {
      return (cleanerId: 'cleaner-01', cleanerName: 'Ramesh Pawar');
    }
    return (cleanerId: 'cleaner-02', cleanerName: 'Sunil Deshmukh');
  }

  /// Checks if the same toilet and issue was reported within the last 15 minutes.
  static bool isDuplicateReport(List<CleanlinessReport> existingReports, String toiletId, CleanlinessIssueType issueType) {
    final now = DateTime.now();
    return existingReports.any((r) {
      if (r.toiletId != toiletId || r.issueType != issueType || r.isResolved) return false;
      final diff = now.difference(r.reportedAt).inMinutes;
      return diff < 15;
    });
  }
}
