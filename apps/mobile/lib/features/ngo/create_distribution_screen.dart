import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/ngo_distribution_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/wari_location_service.dart';
import '../map/widgets/map_location_picker_modal.dart';

/// Form screen for creating/publishing a new NGO Aid Distribution.
class CreateDistributionScreen extends StatefulWidget {
  const CreateDistributionScreen({super.key});

  @override
  State<CreateDistributionScreen> createState() => _CreateDistributionScreenState();
}

class _CreateDistributionScreenState extends State<CreateDistributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '500');
  final _unitController = TextEditingController(text: 'meals');
  final _locationNameController = TextEditingController(text: 'Near Alandi Bus Stand Gate 2');
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController(
    text: 'Please gather orderly. Carry your own bottle if possible.',
  );
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _capacityController = TextEditingController(text: '500');
  final _queueController = TextEditingController(text: '0');
  final _waitMinutesController = TextEditingController(text: '5');

  DistributionCategory _selectedCategory = DistributionCategory.FOOD;
  String _selectedSeverity = 'NORMAL';
  bool _tokensRequired = false;
  bool _untilQuantityLasts = true;
  double _latitude = 18.5204;
  double _longitude = 73.8567;
  double _accuracy = 10.0;
  String _gpsStatus = 'LIVE';
  final DateTime _distributionDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _capacityController.dispose();
    _queueController.dispose();
    _waitMinutesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentGpsLocation() async {
    setState(() => _isLocating = true);
    try {
      final locService = WariLocationService();
      final pos = await locService.getCurrentPosition();
      if (pos.latitude != 0.0 && pos.longitude != 0.0) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _accuracy = pos.accuracy;
          _gpsStatus = pos.status == WariLocationStatus.liveGps ? 'LIVE' : 'SIMULATED';
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPS captured: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (Accuracy: ${pos.accuracy.toInt()}m)'),
              backgroundColor: WariColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _isLocating = false;
          _gpsStatus = 'UNAVAILABLE';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location unavailable. Please enable GPS and try again.'),
              backgroundColor: WariColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await MapLocationPickerModal.show(
      context,
      initialLatitude: _latitude,
      initialLongitude: _longitude,
      title: 'Mark Distribution Spot on Map',
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationNameController.text = result.address;
        _addressController.text = result.address;
        _gpsStatus = 'SELECTED ON MAP';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;
      final distProvider = Provider.of<NgoDistributionProvider>(context, listen: false);

      final qty = int.tryParse(_quantityController.text.trim()) ?? 100;
      final startDt = DateTime(
        _distributionDate.year,
        _distributionDate.month,
        _distributionDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDt = _untilQuantityLasts
          ? null
          : DateTime(
              _distributionDate.year,
              _distributionDate.month,
              _distributionDate.day,
              _endTime.hour,
              _endTime.minute,
            );

      final newDist = ResourceDistribution(
        id: 'dist_${DateTime.now().millisecondsSinceEpoch}',
        ngoId: user?.userId ?? 'ngo-001',
        ngoName: user?.displayName ?? 'Wari Seva NGO',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        quantity: qty,
        unit: _unitController.text.trim().isEmpty ? 'items' : _unitController.text.trim(),
        remainingQuantity: qty,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationNameController.text.trim(),
        address: _addressController.text.trim(),
        distributionDate: _distributionDate,
        startTime: startDt,
        endTime: endDt,
        instructions: _instructionsController.text.trim(),
        servingCapacity: int.tryParse(_capacityController.text.trim()),
        currentQueue: int.tryParse(_queueController.text.trim()),
        estimatedQueueMinutes: int.tryParse(_waitMinutesController.text.trim()),
        tokensRequired: _tokensRequired,
        contactName: _contactNameController.text.trim().isNotEmpty ? _contactNameController.text.trim() : user?.displayName,
        contactPhone: _contactPhoneController.text.trim(),
        severity: _selectedSeverity,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await distProvider.createDistribution(newDist);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Aid Distribution published in real-time across WariVerse!'),
            backgroundColor: WariColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating distribution: $e'), backgroundColor: WariColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Create Resource Distribution'),
        backgroundColor: WariColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.base),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WariCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📦 Aid & Resource Details', style: WariTypography.titleMedium),
                      const SizedBox(height: WariSpacing.sm),

                      DropdownButtonFormField<DistributionCategory>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Resource Category', prefixIcon: Icon(Icons.category)),
                        items: DistributionCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 20),
                                const SizedBox(width: 8),
                                Text(cat.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              if (val == DistributionCategory.FOOD) _unitController.text = 'meals';
                              if (val == DistributionCategory.WATER) _unitController.text = 'bottles';
                              if (val == DistributionCategory.MEDICAL_SUPPLIES || val == DistributionCategory.FIRST_AID) _unitController.text = 'kits';
                              if (val == DistributionCategory.MEDICINE) _unitController.text = 'doses';
                              if (val == DistributionCategory.CLOTHING || val == DistributionCategory.BLANKETS) _unitController.text = 'items';
                              if (val == DistributionCategory.SHELTER) _unitController.text = 'spots';
                              if (val == DistributionCategory.CHARGING) _unitController.text = 'ports';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Distribution Title (e.g. Free Mahaprasad)', prefixIcon: Icon(Icons.title)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter title' : null,
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description)),
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Quantity', prefixIcon: Icon(Icons.pin)),
                              validator: (v) => v == null || int.tryParse(v) == null ? 'Enter quantity' : null,
                            ),
                          ),
                          const SizedBox(width: WariSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _unitController,
                              decoration: const InputDecoration(labelText: 'Unit (meals, bottles)'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter unit' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.base),

                WariCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 Distribution Location & GPS', style: WariTypography.titleMedium),
                      const SizedBox(height: WariSpacing.sm),

                      TextFormField(
                        controller: _locationNameController,
                        decoration: const InputDecoration(labelText: 'Location Name (e.g. Near Alandi Bus Stand)', prefixIcon: Icon(Icons.place)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter location name' : null,
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address / Landmark (optional)', prefixIcon: Icon(Icons.map)),
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      Container(
                        padding: const EdgeInsets.all(WariSpacing.sm),
                        decoration: BoxDecoration(
                          color: _gpsStatus == 'LIVE' || _gpsStatus == 'SELECTED ON MAP' ? WariColors.success.withValues(alpha: 0.1) : WariColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _gpsStatus == 'LIVE' || _gpsStatus == 'SELECTED ON MAP' ? WariColors.success : WariColors.warning),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(_gpsStatus == 'LIVE' || _gpsStatus == 'SELECTED ON MAP' ? Icons.my_location : Icons.location_searching, color: _gpsStatus == 'LIVE' || _gpsStatus == 'SELECTED ON MAP' ? WariColors.success : WariColors.warning, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('GPS Status: $_gpsStatus (Accuracy: ${_accuracy.toInt()}m)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('Lat: ${_latitude.toStringAsFixed(5)}, Lng: ${_longitude.toStringAsFixed(5)}', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: WariSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLocating ? null : _getCurrentGpsLocation,
                                    icon: const Icon(Icons.gps_fixed),
                                    label: const Text('Use Current GPS'),
                                  ),
                                ),
                                const SizedBox(width: WariSpacing.xs),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickLocationOnMap,
                                    icon: const Icon(Icons.map_rounded, color: Colors.white),
                                    label: const Text('Mark on Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.base),

                WariCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⏰ Distribution Time Window', style: WariTypography.titleMedium),
                      const SizedBox(height: WariSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Start Time'),
                              subtitle: Text(_startTime.format(context)),
                              trailing: const Icon(Icons.access_time),
                              onTap: () async {
                                final selected = await showTimePicker(context: context, initialTime: _startTime);
                                if (selected != null) setState(() => _startTime = selected);
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('End Time'),
                              subtitle: Text(_untilQuantityLasts ? 'Until Lasts' : _endTime.format(context)),
                              trailing: const Icon(Icons.access_time_filled),
                              onTap: _untilQuantityLasts
                                  ? null
                                  : () async {
                                      final selected = await showTimePicker(context: context, initialTime: _endTime);
                                      if (selected != null) setState(() => _endTime = selected);
                                    },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available Until Quantity Lasts'),
                        subtitle: const Text('No fixed end time; active until remaining quantity reaches zero.'),
                        value: _untilQuantityLasts,
                        onChanged: (val) => setState(() => _untilQuantityLasts = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.base),

                WariCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📢 Instructions & Crowd Management', style: WariTypography.titleMedium),
                      const SizedBox(height: WariSpacing.sm),

                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Gathering Instructions for Varkaris',
                          prefixIcon: Icon(Icons.campaign),
                        ),
                      ),
                      const SizedBox(height: WariSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _waitMinutesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Est. Wait (Mins)'),
                            ),
                          ),
                          const SizedBox(width: WariSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSeverity,
                              decoration: const InputDecoration(labelText: 'Alert Priority'),
                              items: const [
                                DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                                DropdownMenuItem(value: 'IMPORTANT', child: Text('Important')),
                                DropdownMenuItem(value: 'URGENT', child: Text('URGENT Alert')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSeverity = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Token / Queue Ticket Required'),
                        value: _tokensRequired,
                        onChanged: (val) => setState(() => _tokensRequired = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: WariSpacing.lg),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WariColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('🚀 Publish Real-Time Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
