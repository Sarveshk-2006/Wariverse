import 'package:latlong2/latlong.dart';

/// Pandharpur Wari Palkhi Route Coordinates & Waypoints.
abstract class WariRouteConstants {
  /// Main Vitthal Mandir, Pandharpur center location.
  static final LatLng pandharpurCenter = LatLng(17.6741, 75.3279);

  /// Palkhi route waypoints (Alandi / Dehu -> Pune -> Saswad -> Wakhari -> Pandharpur).
  static final List<LatLng> palkhiRoutePoints = [
    LatLng(18.6754, 73.8967), // Alandi
    LatLng(18.5204, 73.8567), // Pune
    LatLng(18.3428, 73.9872), // Saswad
    LatLng(18.2758, 74.1593), // Jejuri
    LatLng(18.0345, 74.1950), // Lonand
    LatLng(17.9868, 74.4325), // Phaltan
    LatLng(17.8921, 74.7541), // Natepute
    LatLng(17.8420, 74.9080), // Malshiras
    LatLng(17.6845, 75.3160), // Wakhari Ringan Ground
    LatLng(17.6741, 75.3279), // Pandharpur Vitthal Mandir
  ];
}
