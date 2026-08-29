import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// Mock HTTP client for widget tests returning valid backend JSON responses.
class MockTestHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;

    if (path.endsWith('/sos/my-active')) {
      return http.StreamedResponse(
        Stream.value('{"active": false, "incident": null}'.codeUnits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/sos') && request.method == 'POST') {
      final body = '''{
        "id": "sos-test-1234",
        "user_id": "user-test-uuid",
        "latitude": 18.5204,
        "longitude": 73.8567,
        "category": "MEDICAL",
        "status": "CREATED",
        "incident_ref": "WV-SOS-1234",
        "created_at": "2026-08-29T15:00:00Z"
      }''';
      return http.StreamedResponse(
        Stream.value(body.codeUnits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/sos') && request.method == 'GET') {
      return http.StreamedResponse(
        Stream.value('[]'.codeUnits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/food') || path.endsWith('/food/nearby')) {
      final body = '[{"id":"f1","name":"Alandi Annachhatra","provider":"Trust","latitude":18.67,"longitude":73.89,"meal_types":["Mahaprasad"],"available_now":true,"capacity":500,"current_count":120}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/water') || path.endsWith('/water/nearby')) {
      final body = '[{"id":"w1","name":"Hadapsar Water Point","latitude":18.50,"longitude":73.92,"status":"AVAILABLE","capacity_liters":1000}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/toilets') || path.endsWith('/toilets/nearby')) {
      final body = '[{"id":"t1","name":"Mobile Toilet Block A","latitude":18.51,"longitude":73.90,"status":"CLEAN","total_units":4}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/shelters') || path.endsWith('/shelters/nearby')) {
      final body = '[{"id":"s1","name":"Saswad Pilgrim Shelter","latitude":18.34,"longitude":74.03,"capacity":200,"current_occupancy":50}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/medical') || path.endsWith('/medical/nearby')) {
      final body = '[{"id":"m1","name":"Emergency First Aid Camp","latitude":18.52,"longitude":73.85,"location_type":"first_aid","available":true}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/wellness') || path.endsWith('/wellness/nearby')) {
      final body = '[{"id":"wel1","name":"Foot Massage & Reflexology Center","latitude":18.52,"longitude":73.85,"available_now":true}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.contains('/sos/') && (path.endsWith('/resolve') || path.endsWith('/cancel'))) {
      final body = '''{
        "id": "sos-test-1234",
        "user_id": "user-test-uuid",
        "latitude": 18.5204,
        "longitude": 73.8567,
        "category": "MEDICAL",
        "status": "RESOLVED",
        "created_at": "2026-08-29T15:00:00Z"
      }''';
      return http.StreamedResponse(
        Stream.value(body.codeUnits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.endsWith('/emergency-contacts')) {
      return http.StreamedResponse(
        Stream.value('[]'.codeUnits),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/weather')) {
      final body = '{"temperature":28.5,"condition":"Clear","humidity":60,"wind_speed":12.0,"is_from_mock":true}';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/crowd/current')) {
      final body = '[{"id":"z1","name":"Pandharpur Temple","crowd_level":"GREEN","estimated_count":50000}]';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.endsWith('/crowd/prediction')) {
      final body = '{"predicted_level":"GREEN","confidence":0.95,"factors":["Weather OK"]}';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    if (path.contains('/admin')) {
      final body = '{"total_varkaris":250000,"active_volunteers":45,"active_sos":0,"crowd_red_zones":0}';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200, headers: {'content-type': 'application/json'});
    }

    return http.StreamedResponse(
      Stream.value('{}'.codeUnits),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

/// Offline tile provider for unit & widget tests to prevent 400 network tile errors.
class TestTileProvider extends TileProvider {
  static final Uint8List _transparentPng = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentPng);
  }
}
