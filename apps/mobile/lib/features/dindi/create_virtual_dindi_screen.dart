import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/virtual_dindi_model.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../map/widgets/map_location_picker_modal.dart';

class CreateVirtualDindiScreen extends StatefulWidget {
  const CreateVirtualDindiScreen({super.key});

  @override
  State<CreateVirtualDindiScreen> createState() => _CreateVirtualDindiScreenState();
}

class _CreateVirtualDindiScreenState extends State<CreateVirtualDindiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingPointNameController = TextEditingController(text: 'Palkhi Main Halt Point');

  double _meetingLat = 18.5204;
  double _meetingLng = 73.8567;
  double _safeRadius = 75.0;
  double _separationThreshold = 150.0;
  final double _criticalThreshold = 300.0;

  bool _isCreating = false;
  bool _fetchingGps = false;
  VirtualDindi? _createdDindi;

  @override
  void initState() {
    super.initState();
    _fetchCurrentGps();
  }

  Future<void> _fetchCurrentGps() async {
    setState(() => _fetchingGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _meetingLat = pos.latitude;
        _meetingLng = pos.longitude;
        _fetchingGps = false;
      });
    } catch (_) {
      setState(() => _fetchingGps = false);
    }
  }

  Future<void> _pickMeetingPointOnMap() async {
    final result = await MapLocationPickerModal.show(
      context,
      initialLatitude: _meetingLat,
      initialLongitude: _meetingLng,
      title: 'Mark Meeting Spot on Map',
    );

    if (result != null) {
      setState(() {
        _meetingLat = result.latitude;
        _meetingLng = result.longitude;
        _meetingPointNameController.text = result.address;
      });
    }
  }

  Future<void> _submitCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dindiProvider = Provider.of<VirtualDindiProvider>(context, listen: false);

      final user = userProvider.currentUser;
      final uid = user?.userId ?? 'leader_${DateTime.now().millisecondsSinceEpoch}';
      final name = user?.displayName ?? 'Dindi Pramukh';

      final dindi = await dindiProvider.createVirtualDindi(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        leaderUid: uid,
        leaderName: name,
        meetingPointLat: _meetingLat,
        meetingPointLng: _meetingLng,
        meetingPointName: _meetingPointNameController.text.trim(),
        safeRadiusMeters: _safeRadius,
        separationThresholdMeters: _separationThreshold,
        criticalThresholdMeters: _criticalThreshold,
      );

      userProvider.promoteToDindiLeader();

      setState(() {
        _createdDindi = dindi;
        _isCreating = false;
      });
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create Virtual Dindi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Virtual Dindi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.md),
        child: _createdDindi != null ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Setup Group Travel & Separation Thresholds',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
          ),
          const SizedBox(height: WariSpacing.xs),
          const Text(
            'Create a digital Virtual Dindi session for your Palkhi group. Members can join via Join Code or QR scan.',
            style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
          ),
          const SizedBox(height: WariSpacing.md),

          // Dindi Name Input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Virtual Dindi Name *',
              hintText: 'e.g. Alandi Mauli Dindi #101',
              prefixIcon: Icon(Icons.groups_rounded),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a Dindi Name' : null,
          ),
          const SizedBox(height: WariSpacing.base),

          // Description Input
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Optional Description',
              hintText: 'e.g. Pune to Saswad Palkhi Section',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // Reunification Point
          TextFormField(
            controller: _meetingPointNameController,
            decoration: InputDecoration(
              labelText: 'Reunification Meeting Point Name',
              prefixIcon: const Icon(Icons.flag_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _fetchCurrentGps,
                tooltip: 'Use current GPS location',
              ),
            ),
          ),
          const SizedBox(height: WariSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fetchingGps ? null : _fetchCurrentGps,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(_fetchingGps ? 'Getting GPS...' : 'Use Current GPS'),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickMeetingPointOnMap,
                  icon: const Icon(Icons.map_rounded, color: Colors.white),
                  label: const Text('Mark on Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _fetchingGps
                ? 'Acquiring GPS location...'
                : 'GPS Coordinates: ${_meetingLat.toStringAsFixed(5)}, ${_meetingLng.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
          ),
          const SizedBox(height: WariSpacing.lg),

          // Safe Radius Slider
          Text(
            'Safe Boundary Radius: ${_safeRadius.toInt()} meters',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _safeRadius,
            min: 25.0,
            max: 200.0,
            divisions: 7,
            label: '${_safeRadius.toInt()}m',
            onChanged: (val) => setState(() => _safeRadius = val),
          ),
          const SizedBox(height: WariSpacing.base),

          // Separation Threshold Slider
          Text(
            'Separation Alert Threshold: ${_separationThreshold.toInt()} meters',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _separationThreshold,
            min: 100.0,
            max: 400.0,
            divisions: 6,
            label: '${_separationThreshold.toInt()}m',
            onChanged: (val) => setState(() => _separationThreshold = val),
          ),
          const SizedBox(height: WariSpacing.lg),

          ElevatedButton(
            onPressed: _isCreating ? null : _submitCreate,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isCreating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Create Virtual Dindi Session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final dindi = _createdDindi!;
    final qrPayload = 'WV_DINDI:${dindi.dindiId}';

    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: WariColors.success, size: 64),
        const SizedBox(height: WariSpacing.xs),
        Text('Virtual Dindi Created!', style: WariTypography.headlineMedium),
        Text(dindi.name, style: WariTypography.titleMedium.copyWith(color: WariColors.primary)),
        const SizedBox(height: WariSpacing.md),

        // Join Code Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: WariColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(WariSpacing.md),
            border: Border.all(color: WariColors.primary),
          ),
          child: Column(
            children: [
              const Text('JOIN CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WariColors.textSecondary)),
              SelectableText(
                dindi.joinCode,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: WariColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.md),

        // QR Code Container
        Container(
          padding: const EdgeInsets.all(WariSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(WariSpacing.md),
            border: Border.all(color: WariColors.border),
          ),
          child: QrImageView(
            data: qrPayload,
            version: QrVersions.auto,
            size: 200,
            gapless: true,
          ),
        ),
        const SizedBox(height: WariSpacing.xs),
        const Text('Scan QR or enter Join Code to join this session', style: TextStyle(fontSize: 12, color: WariColors.textSecondary)),
        const SizedBox(height: WariSpacing.lg),

        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.dashboard_rounded),
          label: const Text('Open Dindi Dashboard'),
        ),
      ],
    );
  }
}
