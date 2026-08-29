import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/incident_provider.dart';
import '../../models/threat_incident_model.dart';
import '../../core/theme/wari_theme_exports.dart';

class ReportThreatScreen extends StatefulWidget {
  const ReportThreatScreen({super.key});

  @override
  State<ReportThreatScreen> createState() => _ReportThreatScreenState();
}

class _ReportThreatScreenState extends State<ReportThreatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  ThreatCategory _selectedCategory = ThreatCategory.MEDICAL_EMERGENCY;
  IncidentSeverity _selectedSeverity = IncidentSeverity.HIGH;

  double _lat = 18.5204;
  double _lng = 73.8567;
  double _accuracy = 10.0;

  bool _fetchingGps = false;
  bool _isSubmitting = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchRealGps();
  }

  Future<void> _fetchRealGps() async {
    setState(() => _fetchingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _fetchingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _fetchingGps = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _accuracy = pos.accuracy;
        _fetchingGps = false;
      });
    } catch (_) {
      setState(() => _fetchingGps = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<IncidentProvider>(context, listen: false);

      await provider.createIncident(
        category: _selectedCategory,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracyMeters: _accuracy,
        mediaUrls: _photoUrl != null ? [_photoUrl!] : [],
        mediaType: _photoUrl != null ? 'PHOTO' : 'NONE',
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚨 Incident Report submitted! Response team notified.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Threat / Emergency Incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(WariSpacing.md),
                decoration: BoxDecoration(
                  color: WariColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(WariSpacing.md),
                  border: Border.all(color: WariColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: WariColors.danger, size: 32),
                    const SizedBox(width: WariSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Continuous Emergency Response System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.danger)),
                          Text('Your real GPS coordinates and issue details will be dispatched immediately to the nearest responder and Admin Command Center.', style: TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.md),

              // Threat Category Selector
              const Text('1. Select Incident Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: WariSpacing.xs),
              DropdownButtonFormField<ThreatCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: ThreatCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.displayName, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: WariSpacing.md),

              // Severity Selector
              const Text('2. Select Severity Level *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: WariSpacing.xs),
              Row(
                children: IncidentSeverity.values.map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  Color btnColor;
                  switch (sev) {
                    case IncidentSeverity.LOW: btnColor = WariColors.success; break;
                    case IncidentSeverity.MEDIUM: btnColor = WariColors.warning; break;
                    case IncidentSeverity.HIGH: btnColor = WariColors.crowdOrange; break;
                    case IncidentSeverity.CRITICAL: btnColor = WariColors.danger; break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ChoiceChip(
                        label: Text(sev.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : btnColor)),
                        selected: isSelected,
                        selectedColor: btnColor,
                        backgroundColor: btnColor.withValues(alpha: 0.12),
                        onSelected: (val) {
                          if (val) setState(() => _selectedSeverity = sev);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: WariSpacing.md),

              // Description Field
              const Text('3. Description / Details *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: WariSpacing.xs),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the situation, landmarks, or immediate assistance required...',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please describe the incident details' : null,
              ),
              const SizedBox(height: WariSpacing.md),

              // Real Device GPS Coordinates Card
              Container(
                padding: const EdgeInsets.all(WariSpacing.md),
                decoration: BoxDecoration(
                  color: WariColors.surface,
                  borderRadius: BorderRadius.circular(WariSpacing.md),
                  border: Border.all(color: WariColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('4. Auto-Captured Device GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: WariColors.primary),
                          onPressed: _fetchRealGps,
                          tooltip: 'Refresh GPS',
                        ),
                      ],
                    ),
                    Text(
                      _fetchingGps
                          ? 'Acquiring high-accuracy GPS coordinates...'
                          : 'Latitude: ${_lat.toStringAsFixed(6)} | Longitude: ${_lng.toStringAsFixed(6)}\nAccuracy: ±${_accuracy.toInt()}m',
                      style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.lg),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WariColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.send_rounded),
                label: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT EMERGENCY INCIDENT REPORT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
