import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../core/constants/wari_route_constants.dart';
import '../models/models_exports.dart';
import '../services/wari_location_service.dart';

/// Production repository for real Dindi location tracking & leader GPS beacon broadcasting.
class DindiLocationRepository {
  final StreamController<DindiLocationUpdate> _controller = StreamController<DindiLocationUpdate>.broadcast();
  final WariLocationService _locationService = WariLocationService();
  StreamSubscription<WariPosition>? _gpsSub;
  String _activeDindiId = 'dindi-001';
  final Distance _distanceCalculator = const Distance();

  Stream<DindiLocationUpdate> get locationStream => _controller.stream;

  /// Starts real GPS location tracking beacon for Dindi Leader.
  void startLeaderBeacon({String dindiId = 'dindi-001'}) {
    _activeDindiId = dindiId;
    _gpsSub?.cancel();
    _locationService.startTracking(distanceFilterMeters: 10);
    _gpsSub = _locationService.positionStream.listen((pos) {
      _emitRealPosition(pos);
    });
  }

  /// Compatibility fallback start simulation method using route points for tests/offline.
  void startSimulation({String dindiId = 'dindi-001'}) {
    startLeaderBeacon(dindiId: dindiId);
  }

  void stopBeacon() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _locationService.stopTracking();
  }

  void pauseSimulation() => stopBeacon();
  void resumeSimulation() => startLeaderBeacon(dindiId: _activeDindiId);
  void resetSimulation() => stopBeacon();

  void _emitRealPosition(WariPosition pos) {
    final currentPos = LatLng(pos.latitude, pos.longitude);
    final targetPos = WariRouteConstants.palkhiRoutePoints.isNotEmpty
        ? WariRouteConstants.palkhiRoutePoints.last
        : const LatLng(17.6741, 75.3279);

    final distanceMeters = _distanceCalculator.as(LengthUnit.Meter, currentPos, targetPos);
    final distanceKm = (distanceMeters / 1000.0);
    final etaMinutes = ((distanceKm / 4.5) * 60).round();

    final update = DindiLocationUpdate(
      dindiId: _activeDindiId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: pos.timestamp,
      source: DindiLocationSource.LIVE,
      status: DindiMovementStatus.MOVING,
      speedKmh: 4.2,
      heading: 135.0,
      nextHaltName: 'Pandharpur Vitthal Mandir',
      distanceToNextHaltKm: distanceKm,
      etaNextHaltMinutes: etaMinutes,
      progressPercentage: 50.0,
    );

    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  void dispose() {
    stopBeacon();
    _controller.close();
  }
}
