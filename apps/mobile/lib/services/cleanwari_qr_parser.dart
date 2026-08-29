/// QR Code payload parser for CleanWari smart toilet reporting.
class CleanWariQrParser {
  static const String _prefix = 'cleanwari:toilet:';

  /// Generates a non-sensitive opaque QR payload for a toilet facility.
  static String generateToiletPayload(String toiletId) {
    return '$_prefix$toiletId';
  }

  /// Parses a raw QR string and extracts the toiletId. Returns null on invalid input.
  static String? parseToiletPayload(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) return null;
    final trimmed = rawPayload.trim();

    if (!trimmed.startsWith(_prefix)) return null;

    final toiletId = trimmed.substring(_prefix.length).trim();
    if (toiletId.isEmpty) return null;

    return toiletId;
  }

  /// Validates whether a QR payload is an official CleanWari toilet QR string.
  static bool isValidPayload(String? rawPayload) {
    return parseToiletPayload(rawPayload) != null;
  }
}
