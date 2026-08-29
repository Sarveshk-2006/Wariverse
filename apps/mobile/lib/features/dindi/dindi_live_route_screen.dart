import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/wari_route_constants.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/dindi_route_provider.dart';
import '../../repositories/dindi_location_repository.dart';

/// Live Dindi route tracking screen with OpenStreetMap tile layer and simulated GPS updates.
class DindiLiveRouteScreen extends StatelessWidget {
  const DindiLiveRouteScreen({super.key, this.dindiId, this.tileProvider});

  final String? dindiId;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DindiRouteProvider>(
      create: (_) => DindiRouteProvider(
        locationRepository: DindiLocationRepository(),
      )..startTracking(dindiId: dindiId ?? 'dindi-001'),
      child: _DindiLiveRouteContent(tileProvider: tileProvider),
    );
  }
}

class _DindiLiveRouteContent extends StatefulWidget {
  const _DindiLiveRouteContent({this.tileProvider});

  final TileProvider? tileProvider;

  @override
  State<_DindiLiveRouteContent> createState() => _DindiLiveRouteContentState();
}

class _DindiLiveRouteContentState extends State<_DindiLiveRouteContent> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<DindiRouteProvider>(context);
    final location = routeProvider.currentLocation;

    final currentCenter = location != null
        ? LatLng(location.latitude, location.longitude)
        : WariRouteConstants.palkhiRoutePoints.first;

    if (routeProvider.autoFollow && location != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(currentCenter, 14.5);
      });
    }

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Live Dindi Route (थेट रस्ता)'),
        actions: [
          IconButton(
            tooltip: routeProvider.isPaused ? 'Resume Simulation' : 'Pause Simulation',
            icon: Icon(routeProvider.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              if (routeProvider.isPaused) {
                routeProvider.resumeTracking();
              } else {
                routeProvider.pauseTracking();
              }
            },
          ),
          IconButton(
            tooltip: 'Reset Route',
            icon: const Icon(Icons.refresh),
            onPressed: () => routeProvider.resetTracking(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 14.5,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && routeProvider.autoFollow) {
                  routeProvider.toggleAutoFollow(false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.wariverse.mobile',
                tileProvider: widget.tileProvider ?? NetworkTileProvider(
                  headers: {'User-Agent': 'com.wariverse.mobile/1.0'},
                ),
                errorTileCallback: (tile, error, stackTrace) {},
              ),

              // Route Polyline Layer
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: WariRouteConstants.palkhiRoutePoints,
                    strokeWidth: 4.5,
                    color: WariColors.primary,
                  ),
                ],
              ),

              // Dindi Leader Marker Layer
              if (location != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentCenter,
                      width: 90,
                      height: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WariColors.primaryDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🚩 Dindi Leader',
                              style: WariTypography.caption.copyWith(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: WariColors.primary,
                            child: Icon(Icons.flag, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top Demo Tracking Indicator Banner
          Positioned(
            top: WariSpacing.sm,
            left: WariSpacing.base,
            right: WariSpacing.base,
            child: WariCard(
              borderColor: WariColors.warning,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: WariColors.primary, size: 18),
                      const SizedBox(width: WariSpacing.xs),
                      Text('Alandi Mauli Dindi #1', style: WariTypography.titleSmall),
                    ],
                  ),
                  const WariStatusChip(
                    label: '● DEMO TRACKING',
                    color: WariColors.warning,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Button: Center on Dindi
          Positioned(
            right: WariSpacing.base,
            bottom: 190,
            child: FloatingActionButton.small(
              heroTag: 'center_dindi_btn',
              backgroundColor: WariColors.primary,
              onPressed: () {
                routeProvider.toggleAutoFollow(true);
                if (location != null) {
                  _mapController.move(LatLng(location.latitude, location.longitude), 14.5);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Bottom Live Navigation Metrics Panel
          if (location != null)
            Positioned(
              left: WariSpacing.base,
              right: WariSpacing.base,
              bottom: WariSpacing.base,
              child: WariCard(
                borderColor: WariColors.primary,
                borderWidth: 1.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WariStatusChip(
                          label: location.status.displayName,
                          color: location.status == DindiMovementStatus.AT_HALT
                              ? WariColors.warning
                              : WariColors.success,
                          dense: true,
                        ),
                        Text(
                          '${location.progressPercentage.toStringAsFixed(0)}% Completed',
                          style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.xs),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: location.progressPercentage / 100.0,
                        backgroundColor: WariColors.slate200,
                        color: WariColors.primary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: WariSpacing.sm),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next: ${location.nextHaltName}',
                              style: WariTypography.titleMedium,
                            ),
                            Text(
                              '${location.distanceToNextHaltKm.toStringAsFixed(1)} km remaining',
                              style: WariTypography.caption,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(WariSpacing.xs),
                          decoration: BoxDecoration(
                            color: WariColors.primaryLight,
                            borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ETA ${location.etaNextHaltMinutes} min',
                                style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark),
                              ),
                              Text(
                                'Pace: ${location.speedKmh.toStringAsFixed(1)} km/h',
                                style: WariTypography.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
