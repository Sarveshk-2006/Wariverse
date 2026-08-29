import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Centralized logger with production log redaction for sensitive fields.
class AppLogger {
  static void d(String message) {
    if (!EnvConfig.enableDebugLogging) return;
    debugPrint('[DEBUG] ${_sanitize(message)}');
  }

  static void i(String message) {
    if (!EnvConfig.enableDebugLogging) return;
    debugPrint('[INFO] ${_sanitize(message)}');
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!EnvConfig.enableDebugLogging) return;
    debugPrint('[ERROR] ${_sanitize(message)}');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }

  /// Redacts sensitive information like JWT tokens, passwords, and phone numbers from logs.
  static String _sanitize(String text) {
    var sanitized = text;
    // Redact Bearer tokens
    sanitized = sanitized.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'), 'Bearer [REDACTED_TOKEN]');
    // Redact password fields
    sanitized = sanitized.replaceAll(RegExp(r'"password"\s*:\s*"[^"]*"'), '"password": "[REDACTED]"');
    // Redact 10-digit phone numbers
    sanitized = sanitized.replaceAll(RegExp(r'\b[6-9]\d{9}\b'), '[REDACTED_PHONE]');
    return sanitized;
  }
}
