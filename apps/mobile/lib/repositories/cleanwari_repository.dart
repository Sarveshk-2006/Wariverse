import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_exports.dart';
import '../services/api_service.dart';
import '../services/cleanwari_dispatch_service.dart';

/// Repository managing CleanWari cleanliness reports, task dispatch, and status updates.
/// Streams from and persists to Cloud Firestore `sanitation_reports` collection in real time.
class CleanWariRepository {
  final ApiService _apiService;
  final FirebaseFirestore? _firestore;
  final List<CleanlinessReport> _localReports = [];

  CleanWariRepository(this._apiService, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? _tryGetFirestore() {
    _initMockReports();
  }

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
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

  /// Streams live sanitation reports from Cloud Firestore in real time.
  Stream<List<CleanlinessReport>> streamReports() {
    final fs = _firestore;
    if (fs == null) {
      return Stream.value(List.unmodifiable(_localReports));
    }

    return fs.collection('sanitation_reports').orderBy('reported_at', descending: true).snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return List.unmodifiable(_localReports);
      }
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CleanlinessReport.fromJson(data);
      }).toList();
    });
  }

  /// Fetches all active and historical cleanliness reports.
  Future<List<CleanlinessReport>> fetchReports() async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs.collection('sanitation_reports').orderBy('reported_at', descending: true).get();
        if (snap.docs.isNotEmpty) {
          return snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CleanlinessReport.fromJson(data);
          }).toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _apiService.get('/toilets/reports');
      if (res is List) {
        return res.map((item) => CleanlinessReport.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return List.unmodifiable(_localReports);
  }

  /// Fetches tasks assigned to a specific sanitation cleaner staff member.
  Future<List<CleanlinessReport>> fetchCleanerTasks(String cleanerId) async {
    final all = await fetchReports();
    return all.where((r) => r.assignedCleanerId == cleanerId || r.assignedCleanerId == null).toList();
  }

  /// Submits a new cleanliness report to Cloud Firestore.
  Future<CleanlinessReport> submitReport(CleanlinessReport report) async {
    final cleaner = CleanWariDispatchService.assignCleaner(report.toiletId);
    final processed = report.copyWith(
      status: CleanlinessReportStatus.ASSIGNED,
      assignedCleanerId: cleaner.cleanerId,
      assignedCleanerName: cleaner.cleanerName,
    );

    final fs = _firestore;
    if (fs != null) {
      try {
        final docRef = fs.collection('sanitation_reports').doc(processed.id);
        final payload = processed.toJson();
        payload['id'] = processed.id;
        payload['created_at'] = DateTime.now().toIso8601String();
        payload['updated_at'] = DateTime.now().toIso8601String();
        await docRef.set(payload, SetOptions(merge: true));
      } catch (_) {}
    }

    try {
      await _apiService.post('/toilets/${report.toiletId}/report-dirty', {
        'issue_type': report.issueType.name,
        'description': report.description,
      });
    } catch (_) {}

    final index = _localReports.indexWhere((r) => r.id == processed.id);
    if (index == -1) {
      _localReports.insert(0, processed);
    } else {
      _localReports[index] = processed;
    }

    return processed;
  }

  /// Updates report status lifecycle (e.g. ACCEPTED -> IN_PROGRESS -> RESOLVED).
  Future<CleanlinessReport?> updateReportStatus(
    String reportId,
    CleanlinessReportStatus newStatus, {
    String? resolutionNote,
  }) async {
    final index = _localReports.indexWhere((r) => r.id == reportId);
    CleanlinessReport? existing = index != -1 ? _localReports[index] : null;

    final fs = _firestore;
    if (fs != null) {
      try {
        final docRef = fs.collection('sanitation_reports').doc(reportId);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data()!;
          data['id'] = docSnap.id;
          existing = CleanlinessReport.fromJson(data);
        }

        final now = DateTime.now();
        final updates = <String, dynamic>{
          'status': newStatus.name,
          'updated_at': now.toIso8601String(),
        };
        if (resolutionNote != null) updates['resolution_note'] = resolutionNote;
        if (newStatus == CleanlinessReportStatus.RESOLVED) updates['resolved_at'] = now.toIso8601String();

        await docRef.set(updates, SetOptions(merge: true));
      } catch (_) {}
    }

    if (existing != null) {
      final updated = existing.copyWith(
        status: newStatus,
        resolutionNote: resolutionNote,
        resolvedAt: newStatus == CleanlinessReportStatus.RESOLVED ? DateTime.now() : null,
      );

      if (index != -1) {
        _localReports[index] = updated;
      } else {
        _localReports.insert(0, updated);
      }
      return updated;
    }

    return null;
  }
}
