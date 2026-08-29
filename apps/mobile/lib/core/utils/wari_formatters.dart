import 'package:intl/intl.dart';

/// Utility formatting functions for WariVerse AI.
abstract class WariFormatters {
  /// Formats a count with locale-aware comma separation (e.g. 1,400,000).
  static String formatCount(num count) =>
      NumberFormat.decimalPattern().format(count);

  /// Formats a compact count (e.g. 1.4M, 12.5K).
  static String formatCompact(num count) =>
      NumberFormat.compact().format(count);

  /// Formats a distance in meters into human-readable string.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Formats a duration in minutes to human-readable string.
  static String formatWalkTime(int minutes) {
    if (minutes < 60) return '$minutes min walk';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h walk' : '${h}h ${m}min walk';
  }

  /// Formats a density value (0.0–1.0) as a percentage string.
  static String formatDensity(double density) =>
      '${(density * 100).round()}%';

  /// Formats time ago from ISO timestamp.
  static String timeAgo(String isoTimestamp) {
    final dt = DateTime.tryParse(isoTimestamp);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Formats a time string "HH:mm" for display.
  static String formatTime(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(0, 0, 0, h, m);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return hhmm;
    }
  }
}
