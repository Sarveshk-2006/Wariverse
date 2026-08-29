import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../core/constants/wari_route_constants.dart';
import '../../models/models_exports.dart';
import '../../providers/map_provider.dart';
import 'widgets/map_filter_bar.dart';
import 'widgets/marker_detail_bottom_sheet.dart';
import 'widgets/report_issue_bottom_sheet.dart';

/// Full Interactive Live Map & Spatial System view for WariVerse AI.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) => _MapScreenContent(tileProvider: tileProvider),
    );
  }
}

class _MapScreenContent extends StatefulWidget {
  const _MapScreenContent({this.tileProvider});

  final TileProvider? tileProvider;

  @override
  State<_MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<_MapScreenContent> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MapProvider>(context, listen: false).loadMapData();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController.move(WariRouteConstants.pandharpurCenter, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    if (mapProvider.isLoading) {
      return Scaffold(
        backgroundColor: WariColors.background,
        body: const WariLoadingIndicator(message: 'Loading Pilgrimage Map & Services...'),
      );
    }

    final markers = mapProvider.filteredMarkers;
    final crowdZones = mapProvider.crowdZones;
    final selectedMarker = mapProvider.selectedMarker;

    return Scaffold(
      backgroundColor: WariColors.background,
      body: Stack(
        children: [
          // 1. FlutterMap Engine Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: WariRouteConstants.pandharpurCenter,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) => mapProvider.selectMarker(null),
            ),
            children: [
              // Tile Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wariverse.mobile',
                tileProvider: widget.tileProvider ?? NetworkTileProvider(
                  headers: {'User-Agent': 'com.wariverse.mobile/1.0 (Mobile App)'},
                ),
                errorTileCallback: (tile, error, stackTrace) {},
              ),

              // Crowd Zone Circles Layer
              CircleLayer(
                circles: crowdZones.map((zone) {
                  final color = _getCrowdColor(zone.crowdLevel);
                  return CircleMarker(
                    point: zone.location,
                    radius: zone.radiusM > 0 ? zone.radiusM * 0.8 : 400,
                    useRadiusInMeter: true,
                    color: color.withValues(alpha: 0.22),
                    borderColor: color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

              // Wari Palkhi Route Polyline Layer
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: WariRouteConstants.palkhiRoutePoints,
                    strokeWidth: 4.5,
                    color: WariColors.primary,
                  ),
                ],
              ),

              // Service & SOS Marker Layer
              MarkerLayer(
                markers: markers.map((m) {
                  final isSelected = selectedMarker?.id == m.id;

                  return Marker(
                    point: m.location,
                    width: isSelected ? 44 : 36,
                    height: isSelected ? 44 : 36,
                    child: GestureDetector(
                      onTap: () => mapProvider.selectMarker(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: m.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? WariColors.slate900 : Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: WariColors.slate900.withValues(alpha: 0.3),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          m.icon,
                          size: isSelected ? 22 : 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Floating Filter Bar Overlay
          const Positioned(
            top: WariSpacing.xs,
            left: 0,
            right: 0,
            child: SafeArea(child: MapFilterBar()),
          ),

          // 3. Floating Map Controls (Recenter + Report Route Hazard Issue)
          Positioned(
            right: WariSpacing.base,
            bottom: selectedMarker != null ? 220 : WariSpacing.base + 16,
            child: Column(
              children: [
                WariIconButton(
                  icon: Icons.my_location,
                  tooltip: 'Recenter Map',
                  backgroundColor: WariColors.surface,
                  color: WariColors.primary,
                  size: 44,
                  onPressed: _recenterMap,
                ),
                const SizedBox(height: WariSpacing.sm),
                FloatingActionButton.extended(
                  heroTag: 'report_issue_fab',
                  tooltip: '',
                  backgroundColor: WariColors.danger,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text(
                    'Report Issue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    showWariBottomSheet(
                      context: context,
                      child: const ReportIssueBottomSheet(),
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. Selected Marker Detail Bottom Card Overlay
          if (selectedMarker != null)
            Positioned(
              left: WariSpacing.base,
              right: WariSpacing.base,
              bottom: WariSpacing.base,
              child: SafeArea(
                child: MarkerDetailBottomSheet(
                  marker: selectedMarker,
                  onClose: () => mapProvider.selectMarker(null),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return WariColors.crowdGreen;
      case CrowdLevel.YELLOW: return WariColors.crowdYellow;
      case CrowdLevel.ORANGE: return WariColors.crowdOrange;
      case CrowdLevel.RED:    return WariColors.crowdRed;
    }
  }
}
