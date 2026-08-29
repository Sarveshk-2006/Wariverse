import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../services/wari_location_service.dart';

/// Full-screen interactive map picker enabling users to mark any location,
/// automatically resolving reverse-geocoded address and coordinates.
class MapLocationPickerModal extends StatefulWidget {
  const MapLocationPickerModal({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.title = 'Select Spot on Map',
  });

  final double initialLatitude;
  final double initialLongitude;
  final String title;

  static Future<({double latitude, double longitude, String address})?> show(
    BuildContext context, {
    required double initialLatitude,
    required double initialLongitude,
    String title = 'Select Spot on Map',
  }) {
    return showModalBottomSheet<({double latitude, double longitude, String address})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerModal(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
        title: title,
      ),
    );
  }

  @override
  State<MapLocationPickerModal> createState() => _MapLocationPickerModalState();
}

class _MapLocationPickerModalState extends State<MapLocationPickerModal> {
  late final MapController _mapController;
  late double _selectedLat;
  late double _selectedLng;
  String _resolvedAddress = 'Resolving address...';
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLat = (widget.initialLatitude != 0.0) ? widget.initialLatitude : 18.5204;
    _selectedLng = (widget.initialLongitude != 0.0) ? widget.initialLongitude : 73.8567;
    _fetchAddress(_selectedLat, _selectedLng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    setState(() {
      _isResolving = true;
      _selectedLat = lat;
      _selectedLng = lng;
    });
    final addr = await WariLocationService.getAddressFromCoordinates(lat, lng);
    if (mounted) {
      setState(() {
        _resolvedAddress = addr;
        _isResolving = false;
      });
    }
  }

  Future<void> _useCurrentGps() async {
    final pos = await WariLocationService().getCurrentPosition();
    if (pos.latitude != 0.0 && pos.longitude != 0.0) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
      _fetchAddress(pos.latitude, pos.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * 0.82;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.xl)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: WariSpacing.base, vertical: WariSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_location_alt_rounded, color: WariColors.primary, size: 24),
                    const SizedBox(width: WariSpacing.xs),
                    Text(widget.title, style: WariTypography.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Interactive Map Area
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_selectedLat, _selectedLng),
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) {
                      _fetchAddress(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ai.wariverse.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_selectedLat, _selectedLng),
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            size: 44,
                            color: WariColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Action Control: Center on My Current GPS
                Positioned(
                  right: WariSpacing.base,
                  top: WariSpacing.base,
                  child: WariIconButton(
                    icon: Icons.my_location,
                    color: WariColors.primary,
                    onPressed: _useCurrentGps,
                    tooltip: 'Use My Current GPS',
                  ),
                ),

                // Selected Spot Info Banner
                Positioned(
                  left: WariSpacing.base,
                  right: WariSpacing.base,
                  bottom: WariSpacing.base,
                  child: Container(
                    padding: const EdgeInsets.all(WariSpacing.md),
                    decoration: BoxDecoration(
                      color: WariColors.surface,
                      borderRadius: BorderRadius.circular(WariSpacing.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, color: WariColors.primary, size: 20),
                            const SizedBox(width: WariSpacing.xs),
                            Expanded(
                              child: Text(
                                _isResolving ? 'Resolving Address...' : _resolvedAddress,
                                style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coordinates: ${_selectedLat.toStringAsFixed(5)}, ${_selectedLng.toStringAsFixed(5)}',
                          style: WariTypography.caption.copyWith(color: WariColors.textSecondary),
                        ),
                        const SizedBox(height: WariSpacing.sm),
                        WariPrimaryButton(
                          label: 'Confirm Selected Spot',
                          onPressed: () {
                            Navigator.pop(
                              context,
                              (
                                latitude: _selectedLat,
                                longitude: _selectedLng,
                                address: _resolvedAddress,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
