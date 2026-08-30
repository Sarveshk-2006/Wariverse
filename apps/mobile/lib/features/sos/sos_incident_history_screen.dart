import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../repositories/sos_repository.dart';
import '../../repositories/incident_repository.dart';

/// Clean, senior-citizen friendly Emergency & SOS Incident History Screen.
/// Visually aligned with the WariVerse Operations Web Dashboard while remaining
/// optimized for high-contrast mobile field management.
class SosIncidentHistoryScreen extends StatefulWidget {
  const SosIncidentHistoryScreen({super.key});

  @override
  State<SosIncidentHistoryScreen> createState() => _SosIncidentHistoryScreenState();
}

class _SosIncidentHistoryScreenState extends State<SosIncidentHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SOSIncident> _sosIncidents = [];
  List<ThreatIncident> _threatIncidents = [];
  StreamSubscription? _sosSub;
  StreamSubscription? _threatSub;
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, RESOLVED, CRITICAL, HIGH

  @override
  void initState() {
    super.initState();
    _subscribeRealtimeIncidents();
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _threatSub?.cancel();
    super.dispose();
  }

  void _subscribeRealtimeIncidents() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sosRepo = Provider.of<SosRepository>(context, listen: false);
      final incidentRepo = Provider.of<IncidentRepository>(context, listen: false);

      _sosSub?.cancel();
      _sosSub = sosRepo.firestore.collection('sos_incidents').snapshots().listen((snap) {
        final list = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return SOSIncident.fromJson(data);
        }).toList();
        if (mounted) {
          setState(() {
            _sosIncidents = list;
            _isLoading = false;
          });
        }
      }, onError: (err) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Unable to stream live SOS incidents from Firestore: $err';
            _isLoading = false;
          });
        }
      });

      _threatSub?.cancel();
      _threatSub = incidentRepo.streamIncidents().listen((list) {
        if (mounted) {
          setState(() {
            _threatIncidents = list;
            _isLoading = false;
          });
        }
      }, onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'COMPLETED':
        return WariColors.success;
      case 'CREATED':
      case 'PENDING':
      case 'OPEN':
        return WariColors.danger;
      case 'ACKNOWLEDGED':
      case 'ACCEPTED':
        return const Color(0xFFF59E0B); // Amber
      case 'IN_PROGRESS':
      case 'EN_ROUTE':
      case 'ARRIVED':
        return const Color(0xFF8B5CF6); // Purple
      case 'CANCELLED':
      default:
        return WariColors.textMuted;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'URGENT':
        return WariColors.danger;
      case 'HIGH':
      case 'IMPORTANT':
        return const Color(0xFFF97316); // Orange
      case 'MEDIUM':
        return const Color(0xFFF59E0B); // Amber
      case 'LOW':
      case 'NORMAL':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final roleName = userProvider.currentRole.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text('$roleName — SOS & Incident History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _subscribeRealtimeIncidents,
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': 'ACTIVE', 'label': 'Active / Open'},
      {'key': 'RESOLVED', 'label': 'Resolved'},
      {'key': 'CRITICAL', 'label': 'Critical / High'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : WariColors.textPrimary,
                  ),
                ),
                selectedColor: WariColors.primary,
                backgroundColor: WariColors.background,
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = f['key']!;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const WariLoadingIndicator(message: 'Loading emergency incident history...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(WariSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: WariColors.danger),
              const SizedBox(height: WariSpacing.base),
              Text(
                'Unable to load incident history',
                style: WariTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.xs),
              Text(
                _errorMessage!,
                style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.md),
              ElevatedButton.icon(
                onPressed: _subscribeRealtimeIncidents,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY FIREBASE FETCH'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter SOS Incidents
    final filteredSos = _sosIncidents.where((sos) {
      if (_selectedFilter == 'ACTIVE') return sos.status != SOSStatus.RESOLVED && sos.status != SOSStatus.CANCELLED;
      if (_selectedFilter == 'RESOLVED') return sos.status == SOSStatus.RESOLVED;
      if (_selectedFilter == 'CRITICAL') return true; // All emergency SOS are high priority
      return true;
    }).toList();

    // Filter Threat Incidents
    final filteredThreats = _threatIncidents.where((t) {
      if (_selectedFilter == 'ACTIVE') return t.status != IncidentStatus.RESOLVED && t.status != IncidentStatus.CANCELLED;
      if (_selectedFilter == 'RESOLVED') return t.status == IncidentStatus.RESOLVED;
      if (_selectedFilter == 'CRITICAL') return t.severity == IncidentSeverity.CRITICAL || t.severity == IncidentSeverity.HIGH;
      return true;
    }).toList();

    final totalCount = filteredSos.length + filteredThreats.length;

    if (totalCount == 0) {
      return RefreshIndicator(
        onRefresh: () async => _subscribeRealtimeIncidents(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(WariSpacing.lg),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: WariColors.success.withValues(alpha: 0.1),
                    child: const Icon(Icons.verified_user_outlined, size: 40, color: WariColors.success),
                  ),
                  const SizedBox(height: WariSpacing.base),
                  Text('No Incidents Matching Filter', style: WariTypography.titleMedium),
                  const SizedBox(height: WariSpacing.xs),
                  Text(
                    'No emergency alerts or threat reports match the selected criteria in Cloud Firestore.',
                    style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _subscribeRealtimeIncidents(),
      child: ListView(
        padding: const EdgeInsets.all(WariSpacing.base),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WariColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
              border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: WariColors.primary, size: 18),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    'Historical Stream ($totalCount Filtered / ${ _sosIncidents.length + _threatIncidents.length } Total)',
                    style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // SOS Incidents Section
          if (filteredSos.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.emergency_rounded, size: 18, color: WariColors.danger),
                const SizedBox(width: 6),
                Text('🚨 Live SOS Emergency Alerts', style: WariTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),
            ...filteredSos.map((sos) => _buildSosCard(sos)),
            const SizedBox(height: WariSpacing.base),
          ],

          // Threat Incidents Section
          if (filteredThreats.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: WariColors.warning),
                const SizedBox(width: 6),
                Text('⚠️ Threat & Crowd Incidents', style: WariTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),
            ...filteredThreats.map((threat) => _buildThreatCard(threat)),
          ],
        ],
      ),
    );
  }

  Widget _buildSosCard(SOSIncident sos) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(sos.createdAt);
    final statusColor = _getStatusColor(sos.status.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 5),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSosDetailsBottomSheet(sos),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Status + Severity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.emergency_rounded, size: 18, color: WariColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sos.category.displayName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        sos.status.displayName.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sos.description ?? 'Emergency SOS payload triggered by pilgrim.',
                  style: const TextStyle(fontSize: 13, color: WariColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: WariColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${sos.id.length > 8 ? sos.id.substring(0, 8) : sos.id}',
                      style: const TextStyle(fontSize: 11, color: WariColors.textMuted, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: WariColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreatCard(ThreatIncident threat) {
    final createdDt = DateTime.tryParse(threat.createdAt) ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(createdDt);
    final statusColor = _getStatusColor(threat.status.name);
    final severityColor = _getSeverityColor(threat.severity.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 5),
          top: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showThreatDetailsBottomSheet(threat),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Severity + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: severityColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              threat.category.displayName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            threat.severity.displayName.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: severityColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            threat.status.displayName.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reporter: ${threat.reporterName} (${threat.reporterRole})',
                  style: const TextStyle(fontSize: 13, color: WariColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (threat.assignedVolunteerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Responder: ${threat.assignedVolunteerName}',
                    style: const TextStyle(fontSize: 12, color: WariColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: WariColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${threat.incidentId.length > 8 ? threat.incidentId.substring(0, 8) : threat.incidentId}',
                      style: const TextStyle(fontSize: 11, color: WariColors.textMuted, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: WariColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSosDetailsBottomSheet(SOSIncident sos) {
    final statusColor = _getStatusColor(sos.status.name);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(sos.createdAt);
    final mapsUrl = 'https://maps.google.com/?q=${sos.latitude.toStringAsFixed(5)},${sos.longitude.toStringAsFixed(5)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sos.category.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sos.status.displayName,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailItem(Icons.fingerprint, 'Reference ID', sos.id),
              _buildDetailItem(Icons.access_time_rounded, 'Reported At', dateStr),
              _buildDetailItem(
                Icons.location_on_outlined,
                'GPS Coordinates',
                '${sos.latitude.toStringAsFixed(4)}, ${sos.longitude.toStringAsFixed(4)}',
              ),
              _buildDetailItem(Icons.description_outlined, 'Details', sos.description ?? 'Standard SOS Emergency Trigger'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WariColors.primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(mapsUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: const Text('Open Incident Location in Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThreatDetailsBottomSheet(ThreatIncident threat) {
    final statusColor = _getStatusColor(threat.status.name);
    final severityColor = _getSeverityColor(threat.severity.name);
    final createdDt = DateTime.tryParse(threat.createdAt) ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(createdDt);
    final mapsUrl = 'https://maps.google.com/?q=${threat.latitude.toStringAsFixed(5)},${threat.longitude.toStringAsFixed(5)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      threat.category.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          threat.severity.displayName,
                          style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          threat.status.displayName,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailItem(Icons.fingerprint, 'Incident ID', threat.incidentId),
              _buildDetailItem(Icons.person_outline, 'Reporter', '${threat.reporterName} (${threat.reporterRole})'),
              _buildDetailItem(Icons.support_agent_rounded, 'Assigned Responder', threat.assignedVolunteerName ?? 'Unassigned / Field Queue'),
              _buildDetailItem(Icons.access_time_rounded, 'Created At', dateStr),
              if (threat.resolvedAt != null)
                _buildDetailItem(Icons.check_circle_outline_rounded, 'Resolved At', threat.resolvedAt!),
              _buildDetailItem(
                Icons.location_on_outlined,
                'GPS Location',
                '${threat.latitude.toStringAsFixed(4)}, ${threat.longitude.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WariColors.primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(mapsUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: const Text('Open Incident Location in Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: WariColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: WariColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
