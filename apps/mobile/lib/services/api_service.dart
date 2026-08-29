import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../core/errors/app_exception.dart';

/// Result type carrying both data and source information.
class ApiResult<T> {
  final T data;
  final bool isFromMock;

  const ApiResult(this.data, {this.isFromMock = false});
}

/// Centralized HTTP service for WariVerse AI.
/// All network calls go through this class — widgets never call http directly.
class ApiService {
  ApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  String? _authToken;

  static final Duration _timeout =
      Duration(seconds: EnvConfig.connectTimeoutSeconds);

  /// Set bearer token for authenticated requests.
  void setToken(String? token) => _authToken = token;

  // ── Core HTTP Methods ────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    try {
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException {
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnavailable();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path, null);
    try {
      final response = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException {
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnavailable();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  /// Special handler for OAuth2 form-encoded login endpoint.
  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final uri = _buildUri(path, null);
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: fields,
          )
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException {
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnavailable();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path, null);
    try {
      final response = await _client
          .patch(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException {
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnavailable();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path, null);
    try {
      final response = await _client
          .delete(uri, headers: _headers())
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw AppException.timeout();
    } on SocketException {
      throw AppException.noInternet();
    } on http.ClientException {
      throw AppException.serverUnavailable();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(e.toString());
    }
  }


  // ── Health Check ─────────────────────────────────────────────

  /// Returns true if the backend is reachable.
  Future<bool> isBackendReachable() async {
    try {
      await get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = EnvConfig.apiBaseUrl;
    final uri = Uri.parse('$base$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    return h;
  }

  dynamic _parse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw AppException.invalidJson(e.toString());
      }
    }
    throw AppException.http(response.statusCode, response.body);
  }
}
