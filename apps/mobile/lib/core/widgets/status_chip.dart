import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Crowd severity level used for status chips.
enum CrowdSeverity { green, yellow, orange, red }

/// Generic severity level for alerts.
enum AlertSeverity { safe, caution, warning, critical }

/// Service availability status.
enum ServiceStatus { available, low, unavailable, unknown }

/// Compact status chip — mirrors the colored status pills on the web dashboard.
class WariStatusChip extends StatelessWidget {
  const WariStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? WariSpacing.sm : WariSpacing.md,
        vertical: dense ? 2 : WariSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: WariTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Crowd-level specific chip with preset colors.
class CrowdLevelChip extends StatelessWidget {
  const CrowdLevelChip({super.key, required this.level, this.dense = false});

  final CrowdSeverity level;
  final bool dense;

  static const _labels = {
    CrowdSeverity.green: 'Safe',
    CrowdSeverity.yellow: 'Moderate',
    CrowdSeverity.orange: 'High',
    CrowdSeverity.red: 'Critical',
  };

  static const _colors = {
    CrowdSeverity.green: WariColors.crowdGreen,
    CrowdSeverity.yellow: WariColors.crowdYellow,
    CrowdSeverity.orange: WariColors.crowdOrange,
    CrowdSeverity.red: WariColors.crowdRed,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[level]!;
    final label = _labels[level]!;
    return WariStatusChip(
      label: label,
      color: color,
      dense: dense,
    );
  }
}

/// Alert severity chip with preset colors.
class AlertSeverityChip extends StatelessWidget {
  const AlertSeverityChip({super.key, required this.severity, this.dense = false});

  final AlertSeverity severity;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (severity) {
      case AlertSeverity.safe:
        color = WariColors.success;
        label = 'Safe';
      case AlertSeverity.caution:
        color = WariColors.crowdYellow;
        label = 'Caution';
      case AlertSeverity.warning:
        color = WariColors.crowdOrange;
        label = 'Warning';
      case AlertSeverity.critical:
        color = WariColors.danger;
        label = 'Critical';
    }
    return WariStatusChip(label: label, color: color, dense: dense);
  }
}

/// Service availability chip.
class ServiceStatusChip extends StatelessWidget {
  const ServiceStatusChip({super.key, required this.status, this.dense = false});

  final ServiceStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ServiceStatus.available:
        color = WariColors.success;
        label = 'Available';
      case ServiceStatus.low:
        color = WariColors.crowdYellow;
        label = 'Low';
      case ServiceStatus.unavailable:
        color = WariColors.danger;
        label = 'Unavailable';
      case ServiceStatus.unknown:
        color = WariColors.slate400;
        label = 'Unknown';
    }
    return WariStatusChip(label: label, color: color, dense: dense);
  }
}

/// Small colored dot indicator used in map legends and list items.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 8.0});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
