/// Domain service for centralizing Dindi QR payload generation and safe validation.
abstract class DindiQrParser {
  static const String joinPrefix = 'dindi:join:';
  static const String passPrefix = 'dindi-pass:';

  /// Generates non-sensitive opaque join QR payload.
  static String generateJoinPayload(String dindiId) {
    return '$joinPrefix${dindiId.trim()}';
  }

  /// Generates non-sensitive opaque pass QR payload.
  static String generatePassPayload(String passId) {
    return '$passPrefix${passId.trim()}';
  }

  /// Extracts Dindi ID from raw QR payload safely without throwing errors.
  static String? parseJoinPayload(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.startsWith(joinPrefix)) {
        final dindiId = trimmed.substring(joinPrefix.length).trim();
        if (dindiId.isNotEmpty) return dindiId;
      }
    } catch (_) {
      // Return null on parsing failure
    }
    return null;
  }

  /// Extracts Pass ID from raw QR payload safely without throwing errors.
  static String? parsePassPayload(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.startsWith(passPrefix)) {
        final passId = trimmed.substring(passPrefix.length).trim();
        if (passId.isNotEmpty) return passId;
      }
    } catch (_) {
      // Return null on parsing failure
    }
    return null;
  }

  /// Evaluates whether raw string is a valid Dindi QR payload.
  static bool isValidPayload(String raw) {
    return parseJoinPayload(raw) != null || parsePassPayload(raw) != null;
  }
}
