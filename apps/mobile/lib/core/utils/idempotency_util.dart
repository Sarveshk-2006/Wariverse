import 'dart:math';

/// Utility generating unique client-side idempotency keys to prevent duplicate mutation requests.
class IdempotencyUtil {
  static final _random = Random.secure();

  /// Generates a client-side UUID v4 style idempotency key for SOS / mutation operations.
  static String generateKey() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 1

    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
