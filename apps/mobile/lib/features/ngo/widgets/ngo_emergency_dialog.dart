import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/sos_provider.dart';
import '../../../services/wari_location_service.dart';

/// NGO Operations Emergency Trigger Modal for Distribution Site Hazards & Crowd Risks.
class NgoEmergencyDialog extends StatefulWidget {
  const NgoEmergencyDialog({super.key});

  @override
  State<NgoEmergencyDialog> createState() => _NgoEmergencyDialogState();
}

class _NgoEmergencyDialogState extends State<NgoEmergencyDialog> {
  final TextEditingController _notesController = TextEditingController();
  SOSCategory _selectedCategory = SOSCategory.MEDICAL;
  bool _isSubmitting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitNgoEmergency() async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = 'Acquiring real device GPS location...';
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sosProvider = Provider.of<SosProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    try {
      final pos = await WariLocationService().getCurrentPosition();

      setState(() {
        _statusMessage = 'Transmitting emergency payload to Command Center...';
      });

      await sosProvider.triggerSos(
        category: _selectedCategory,
        latitude: pos.latitude,
        longitude: pos.longitude,
        description: 'NGO Emergency: ${_selectedCategory.displayName}. ${_notesController.text.trim()}',
        userId: currentUser?.userId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 NGO Operational Emergency Dispatched to Wari Command Center!'),
          backgroundColor: WariColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Location / Dispatch error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: WariColors.danger, size: 28),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    'NGO Operational Emergency',
                    style: WariTypography.headlineSmall.copyWith(color: WariColors.danger),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),
            Text(
              'Report distribution site hazards directly to Wari Command Center, Police, and Medical responders.',
              style: WariTypography.bodySmall,
            ),
            const SizedBox(height: WariSpacing.base),

            Text('Emergency Category', style: WariTypography.labelSmall),
            const SizedBox(height: WariSpacing.xs),
            DropdownButtonFormField<SOSCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(
                  value: SOSCategory.MEDICAL,
                  child: Text('🚑 Distribution Site Medical Emergency'),
                ),
                DropdownMenuItem(
                  value: SOSCategory.ACCIDENT,
                  child: Text('⚠️ Stampede / Heavy Crowd Surge Risk'),
                ),
                DropdownMenuItem(
                  value: SOSCategory.WOMEN_SAFETY,
                  child: Text('👶 Missing Child / Lost Person Report'),
                ),
                DropdownMenuItem(
                  value: SOSCategory.OTHER,
                  child: Text('🚰 Water / Sanitation Infrastructure Failure'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),

            const SizedBox(height: WariSpacing.base),
            Text('Operational Notes / Additional Context', style: WariTypography.labelSmall),
            const SizedBox(height: WariSpacing.xs),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Specify exact landmark, estimated crowd size, or required aid...',
                border: OutlineInputBorder(),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: WariSpacing.sm),
              Text(
                _statusMessage!,
                style: const TextStyle(fontSize: 12, color: WariColors.danger, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: WariSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: WariSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitNgoEmergency,
                    icon: _isSubmitting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('DISPATCH SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.danger,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
