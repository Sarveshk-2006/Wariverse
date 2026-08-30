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

/// Clean read-only Emergency & SOS Incident History Screen for Admin and NGO Mobile Portals.
/// Real-time powered directly by Cloud Firestore incidents / sos_incidents collections.
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

  @override
  void initState() {
    super.initState();
    _fetchHistoricalIncidents();
  }

  Future<void> _fetchHistoricalIncidents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sosRepo = Provider.of<SosRepository>(context, listen: false);
      final incidentRepo = Provider.of<IncidentRepository>(context, listen: false);

      final sosResult = await sosRepo.getIncidents();
      final threatList = await incidentRepo.getIncidents();

      if (mounted) {
        setState(() {
          _sosIncidents = sosResult.incidents;
          _threatIncidents = threatList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
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
            onPressed: _fetchHistoricalIncidents,
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const WariLoadingIndicator(message: 'Loading historical emergency incidents from Cloud Firestore...');
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
                onPressed: _fetchHistoricalIncidents,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RETRY FIREBASE FETCH'),
              ),
            ],
          ),
        ),
      );
    }

    // Combine SOS and Threat incidents
    final allCount = _sosIncidents.length + _threatIncidents.length;

    if (allCount == 0) {
      return RefreshIndicator(
        onRefresh: _fetchHistoricalIncidents,
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
                  Text('No Emergency Incidents Reported', style: WariTypography.titleMedium),
                  const SizedBox(height: WariSpacing.xs),
                  Text(
                    'No historical emergency SOS alerts or threat reports found in Cloud Firestore.',
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
      onRefresh: _fetchHistoricalIncidents,
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
                    'Historical Record Stream ($allCount Firestore Records)',
                    style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // SOS Incidents Section
          if (_sosIncidents.isNotEmpty) ...[
            Text('🚨 Emergency SOS Alerts', style: WariTypography.titleSmall),
            const SizedBox(height: WariSpacing.xs),
            ..._sosIncidents.map((sos) => _buildSosCard(sos)),
            const SizedBox(height: WariSpacing.base),
          ],

          // Threat Incidents Section
          if (_threatIncidents.isNotEmpty) ...[
            Text('⚠️ Reported Threat Incidents', style: WariTypography.titleSmall),
            const SizedBox(height: WariSpacing.xs),
            ..._threatIncidents.map((threat) => _buildThreatCard(threat)),
          ],
        ],
      ),
    );
  }

  Widget _buildSosCard(SOSIncident sos) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(sos.createdAt);
    final mapsUrl = 'https://maps.google.com/?q=${sos.latitude.toStringAsFixed(5)},${sos.longitude.toStringAsFixed(5)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: WariSpacing.sm),
      child: WariCard(
        borderColor: WariColors.danger.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SOS REF: ${sos.id}',
                    style: WariTypography.titleSmall.copyWith(color: WariColors.danger),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                WariStatusChip(
                  label: sos.status.displayName,
                  color: sos.status == SOSStatus.RESOLVED ? WariColors.success : WariColors.danger,
                  dense: true,
                ),
              ],
            ),
            const Divider(height: 16),
            _buildDetailRow(Icons.category_outlined, 'Category', sos.category.displayName),
            _buildDetailRow(Icons.person_outline, 'Reporter', sos.description ?? 'Anonymous Varkari'),
            _buildDetailRow(Icons.access_time_rounded, 'Created', dateStr),
            _buildDetailRow(Icons.near_me_outlined, 'Location', '${sos.latitude.toStringAsFixed(4)}, ${sos.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(mapsUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 14, color: WariColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Open Location in Google Maps',
                    style: WariTypography.caption.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatCard(ThreatIncident threat) {
    final createdDt = DateTime.tryParse(threat.createdAt) ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(createdDt);
    final mapsUrl = 'https://maps.google.com/?q=${threat.latitude.toStringAsFixed(5)},${threat.longitude.toStringAsFixed(5)}';

    final resolvedDt = threat.resolvedAt != null ? DateTime.tryParse(threat.resolvedAt!) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: WariSpacing.sm),
      child: WariCard(
        borderColor: WariColors.primary.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'INCIDENT REF: ${threat.incidentId}',
                    style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                WariStatusChip(
                  label: threat.status.displayName,
                  color: threat.status == IncidentStatus.RESOLVED ? WariColors.success : WariColors.warning,
                  dense: true,
                ),
              ],
            ),
            const Divider(height: 16),
            _buildDetailRow(Icons.warning_amber_rounded, 'Category', threat.category.displayName),
            _buildDetailRow(Icons.bar_chart_rounded, 'Severity', threat.severity.displayName),
            _buildDetailRow(Icons.person_outline, 'Reporter', '${threat.reporterName} (${threat.reporterRole})'),
            _buildDetailRow(Icons.support_agent_rounded, 'Assigned Responder', threat.assignedVolunteerName ?? 'Unassigned / Command Stream'),
            _buildDetailRow(Icons.access_time_rounded, 'Created', dateStr),
            if (resolvedDt != null)
              _buildDetailRow(Icons.check_circle_outline_rounded, 'Resolved At', DateFormat('MMM dd, yyyy • hh:mm a').format(resolvedDt)),
            _buildDetailRow(Icons.near_me_outlined, 'Location', '${threat.latitude.toStringAsFixed(4)}, ${threat.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(mapsUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 14, color: WariColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Open Location in Google Maps',
                    style: WariTypography.caption.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: WariColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ', style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: WariTypography.caption.copyWith(color: WariColors.textPrimary),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
