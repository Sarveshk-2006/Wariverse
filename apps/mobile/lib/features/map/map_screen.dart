import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../core/constants/wari_route_constants.dart';
import '../../models/models_exports.dart';
import '../../models/map_marker_item.dart';
import '../../services/api_service.dart';
import '../../repositories/repositories_exports.dart';
import '../../providers/map_provider.dart';
import '../../providers/offline_map_provider.dart';
import 'widgets/map_filter_bar.dart';
import 'widgets/marker_detail_bottom_sheet.dart';
import 'widgets/report_issue_bottom_sheet.dart';
import 'widgets/download_offline_map_modal.dart';
import 'widgets/manage_offline_maps_modal.dart';
import 'widgets/offline_search_sheet.dart';

/// Full Interactive Live Map & Spatial System view for WariVerse AI.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final existingMap = Provider.of<MapProvider?>(context, listen: false);
    final existingOffline = Provider.of<OfflineMapProvider?>(context, listen: false);

    if (existingMap != null && existingOffline != null) {
      return Consumer<MapProvider>(
        builder: (context, mapProvider, _) => _MapScreenContent(tileProvider: tileProvider),
      );
    }

    final apiService = Provider.of<ApiService>(context, listen: false);

    return MultiProvider(
      providers: [
        if (existingMap == null)
          ChangeNotifierProvider<MapProvider>(
            create: (_) => MapProvider(
              serviceRepo: ServiceRepository(apiService),
              crowdRepo: CrowdRepository(apiService),
              sosRepo: SosRepository(apiService),
            ),
          ),
        if (existingOffline == null)
          ChangeNotifierProvider<OfflineMapProvider>(
            create: (_) => OfflineMapProvider(),
          ),
      ],
      child: Consumer<MapProvider>(
        builder: (context, mapProvider, _) => _MapScreenContent(tileProvider: tileProvider),
      ),
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
    final offlineProvider = Provider.of<OfflineMapProvider?>(context);

    if (mapProvider.isLoading) {
      return Scaffold(
        backgroundColor: WariColors.background,
        body: const WariLoadingIndicator(message: 'Loading Pilgrimage Map & Services...'),
      );
    }

    final isOffline = offlineProvider?.isOfflineMode == true || offlineProvider?.isOfflineNavigationActive == true;
    final snapshot = offlineProvider?.activeSnapshot;

    final markers = isOffline && snapshot != null
        ? _buildOfflineMarkers(snapshot)
        : mapProvider.filteredMarkers;
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
              // Tile Layer (OpenStreetMap with fallback)
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

          // 2. Connectivity Status Banner Overlay
          if (offlineProvider != null)
            Positioned(
              top: WariSpacing.xs,
              left: WariSpacing.base,
              right: WariSpacing.base,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getConnectivityBgColor(offlineProvider.status),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          offlineProvider.statusBadgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getConnectivityTextColor(offlineProvider.status),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOffline && snapshot != null)
                        Text(
                          'Last updated: ${snapshot.relativeAgeString}',
                          style: TextStyle(fontSize: 10, color: _getConnectivityTextColor(offlineProvider.status)),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Filter Bar Overlay
          const Positioned(
            top: 42.0,
            left: 0,
            right: 0,
            child: SafeArea(child: MapFilterBar()),
          ),

          // 4. Floating Controls Overlay (Download Offline, Manage Maps, Search, Recenter, Report Hazard)
          Positioned(
            right: WariSpacing.base,
            bottom: selectedMarker != null ? 220 : WariSpacing.base + 16,
            child: Column(
              children: [
                WariIconButton(
                  icon: isOffline ? Icons.wifi_off_rounded : Icons.download_for_offline_rounded,
                  tooltip: 'Download Offline Map',
                  backgroundColor: isOffline ? WariColors.warning : WariColors.surface,
                  color: isOffline ? Colors.white : WariColors.primary,
                  size: 44,
                  onPressed: () {
                    showWariBottomSheet(
                      context: context,
                      child: const DownloadOfflineMapModal(),
                    );
                  },
                ),
                const SizedBox(height: WariSpacing.xs),
                WariIconButton(
                  icon: Icons.folder_zip_rounded,
                  tooltip: 'Manage Offline Maps',
                  backgroundColor: WariColors.surface,
                  color: WariColors.accent,
                  size: 44,
                  onPressed: () {
                    showWariBottomSheet(
                      context: context,
                      child: const ManageOfflineMapsModal(),
                    );
                  },
                ),
                const SizedBox(height: WariSpacing.xs),
                WariIconButton(
                  icon: Icons.search_rounded,
                  tooltip: 'Offline Search',
                  backgroundColor: WariColors.surface,
                  color: WariColors.info,
                  size: 44,
                  onPressed: () {
                    showWariBottomSheet(
                      context: context,
                      child: const OfflineSearchSheet(),
                    );
                  },
                ),
                const SizedBox(height: WariSpacing.xs),
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

          // 5. Selected Marker Detail Bottom Card Overlay
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

  static Color _getConnectivityBgColor(LiveMapConnectivityStatus status) {
    switch (status) {
      case LiveMapConnectivityStatus.online:
        return WariColors.success.withValues(alpha: 0.95);
      case LiveMapConnectivityStatus.downloading:
        return WariColors.info.withValues(alpha: 0.95);
      case LiveMapConnectivityStatus.offline:
        return WariColors.warning.withValues(alpha: 0.95);
      case LiveMapConnectivityStatus.reconnecting:
        return WariColors.accent.withValues(alpha: 0.95);
      case LiveMapConnectivityStatus.updated:
        return WariColors.success.withValues(alpha: 0.95);
    }
  }

  static Color _getConnectivityTextColor(LiveMapConnectivityStatus status) {
    return Colors.white;
  }

  static Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return WariColors.crowdGreen;
      case CrowdLevel.YELLOW: return WariColors.crowdYellow;
      case CrowdLevel.ORANGE: return WariColors.crowdOrange;
      case CrowdLevel.RED:    return WariColors.crowdRed;
    }
  }

  List<MapMarkerItem> _buildOfflineMarkers(OfflineMapSnapshot snapshot) {
    final List<MapMarkerItem> list = [];

    for (final item in snapshot.foodCentres) {
      list.add(MapMarkerItem(
        id: item['id']?.toString() ?? 'food',
        layer: 'food',
        title: item['name'] as String? ?? 'Food Centre',
        statusLabel: 'Food · Snapshot ${snapshot.relativeAgeString}',
        latitude: (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude,
        longitude: (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude,
        icon: Icons.restaurant,
        color: WariColors.success,
      ));
    }

    for (final item in snapshot.waterPoints) {
      list.add(MapMarkerItem(
        id: item['id']?.toString() ?? 'water',
        layer: 'water',
        title: item['name'] as String? ?? 'Water Point',
        statusLabel: 'Water · Snapshot ${snapshot.relativeAgeString}',
        latitude: (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude,
        longitude: (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude,
        icon: Icons.water_drop,
        color: WariColors.info,
      ));
    }

    for (final item in snapshot.medicalLocations) {
      list.add(MapMarkerItem(
        id: item['id']?.toString() ?? 'medical',
        layer: 'medical',
        title: item['name'] as String? ?? 'Medical Centre',
        statusLabel: 'Medical · Doctors & First Aid',
        latitude: (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude,
        longitude: (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude,
        icon: Icons.local_hospital,
        color: WariColors.warning,
      ));
    }

    for (final item in snapshot.toilets) {
      list.add(MapMarkerItem(
        id: item['id']?.toString() ?? 'toilet',
        layer: 'toilets',
        title: item['name'] as String? ?? 'Mobile Toilet Block',
        statusLabel: 'Sanitation · Snapshot ${snapshot.relativeAgeString}',
        latitude: (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude,
        longitude: (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude,
        icon: Icons.wc,
        color: WariColors.primary,
      ));
    }

    for (final item in snapshot.shelters) {
      list.add(MapMarkerItem(
        id: item['id']?.toString() ?? 'shelter',
        layer: 'shelters',
        title: item['name'] as String? ?? 'Pilgrim Shelter',
        statusLabel: 'Shelter · Capacity: ${item['total_capacity'] ?? 200}',
        latitude: (item['latitude'] as num?)?.toDouble() ?? snapshot.centerLatitude,
        longitude: (item['longitude'] as num?)?.toDouble() ?? snapshot.centerLongitude,
        icon: Icons.night_shelter,
        color: WariColors.accent,
      ));
    }

    return list;
  }
}
