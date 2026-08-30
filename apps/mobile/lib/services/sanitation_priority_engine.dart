import '../models/cleanliness_report.dart';

/// Deterministic Sanitation Priority Calculation Engine.
/// Automatically calculates task priority (CRITICAL, HIGH, MEDIUM, LOW) based on:
/// - Issue Category & Severity
/// - Keywords in description (e.g. overflow, blocked, health hazard)
/// - Proximity density (number of reports nearby)
/// - Report age (unresolved duration)
class SanitationPriorityEngine {
  static CleanlinessReportPriority calculatePriority({
    required CleanlinessIssueType issueType,
    required String description,
    int nearbyUnresolvedCount = 0,
    int minutesUnresolved = 0,
  }) {
    int score = 0;

    // 1. Base score from Issue Category
    switch (issueType) {
      case CleanlinessIssueType.OVERFLOW:
        score += 40;
        break;
      case CleanlinessIssueType.NO_WATER:
        score += 30;
        break;
      case CleanlinessIssueType.DAMAGED:
        score += 25;
        break;
      case CleanlinessIssueType.NEEDS_CLEANING:
        score += 15;
        break;
      case CleanlinessIssueType.OTHER:
        score += 10;
        break;
    }

    // 2. Keyword urgency analysis
    final lowerDesc = description.toLowerCase();
    if (lowerDesc.contains('overflow') || lowerDesc.contains('flooding') || lowerDesc.contains('hazard') || lowerDesc.contains('emergency') || lowerDesc.contains('blockage')) {
      score += 30;
    }
    if (lowerDesc.contains('stink') || lowerDesc.contains('dirty') || lowerDesc.contains('smell')) {
      score += 10;
    }

    // 3. Proximity report density (multiple reports near same location)
    score += (nearbyUnresolvedCount * 15);

    // 4. Age of unresolved report
    if (minutesUnresolved > 60) {
      score += 25;
    } else if (minutesUnresolved > 30) {
      score += 15;
    }

    // Map score to Priority Tier
    if (score >= 60) {
      return CleanlinessReportPriority.CRITICAL;
    } else if (score >= 40) {
      return CleanlinessReportPriority.HIGH;
    } else if (score >= 20) {
      return CleanlinessReportPriority.MEDIUM;
    } else {
      return CleanlinessReportPriority.LOW;
    }
  }

  /// Safe GPS Coordinate Validator shielding against 0, NaN, or out-of-bounds lat/lon.
  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat < -90.0 || lat > 90.0) return false;
    if (lng < -180.0 || lng > 180.0) return false;
    return true;
  }
}
