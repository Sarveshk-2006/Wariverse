import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/wari_theme_exports.dart';

class JoinVirtualDindiModal extends StatefulWidget {
  const JoinVirtualDindiModal({super.key});

  @override
  State<JoinVirtualDindiModal> createState() => _JoinVirtualDindiModalState();
}

class _JoinVirtualDindiModalState extends State<JoinVirtualDindiModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _processJoin(String inputCode) async {
    final cleanInput = inputCode.trim();
    if (cleanInput.isEmpty) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dindiProvider = Provider.of<VirtualDindiProvider>(context, listen: false);

      final user = userProvider.currentUser;
      final uid = user?.userId ?? 'varkari_${DateTime.now().millisecondsSinceEpoch}';
      final name = user?.displayName ?? 'Varkari Pilgrim';
      final role = userProvider.currentRole.name;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      } catch (_) {
        pos = Position(latitude: 18.5204, longitude: 73.8567, timestamp: DateTime.now(), accuracy: 10, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
      }

      // Handle QR prefix: 'WV_DINDI:<dindiId>'
      String targetCode = cleanInput;
      if (cleanInput.startsWith('WV_DINDI:')) {
        targetCode = cleanInput.substring('WV_DINDI:'.length).trim();
      }

      final dindi = await dindiProvider.joinVirtualDindi(
        codeOrId: targetCode,
        uid: uid,
        displayName: name,
        role: role,
        currentLat: pos.latitude,
        currentLng: pos.longitude,
      );

      setState(() => _isJoining = false);

      if (dindi != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully joined ${dindi.name}!')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _errorMessage = 'No active Virtual Dindi found for code: $cleanInput');
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
        _errorMessage = 'Error joining Dindi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.xl)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Join Virtual Dindi', style: WariTypography.headlineMedium.copyWith(fontSize: 18)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pin), text: 'Enter Code'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            ],
          ),
          const SizedBox(height: WariSpacing.md),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(WariSpacing.sm),
              margin: const EdgeInsets.only(bottom: WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WariColors.danger),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: WariColors.danger, fontSize: 12)),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Enter Code Tab
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Enter 4-Digit Dindi Join Code',
                        hintText: 'e.g. VDND-1234',
                        prefixIcon: Icon(Icons.groups_rounded),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.lg),
                    ElevatedButton(
                      onPressed: _isJoining ? null : () => _processJoin(_codeController.text),
                      child: _isJoining
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Join Dindi Session'),
                    ),
                  ],
                ),

                // Scan QR Tab
                ClipRRect(
                  borderRadius: BorderRadius.circular(WariSpacing.md),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        _processJoin(barcodes.first.rawValue!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
