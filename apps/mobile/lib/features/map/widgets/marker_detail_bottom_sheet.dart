import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/map_marker_item.dart';

/// Bottom sheet widget displaying selected map marker details.
class MarkerDetailBottomSheet extends StatelessWidget {
  const MarkerDetailBottomSheet({
    super.key,
    required this.marker,
    required this.onClose,
  });

  final MapMarkerItem marker;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final layerColor = MapMarkerItem.getLayerColor(marker.layer);
    final categoryLabel = MapMarkerItem.getLayerLabel(marker.layer);

    return WariCard(
      elevation: WariSpacing.elevationLg,
      radius: WariSpacing.radiusLg,
      borderColor: layerColor.withValues(alpha: 0.3),
      borderWidth: 1.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(marker.icon, size: 18, color: layerColor),
                  const SizedBox(width: WariSpacing.xs),
                  Text(
                    categoryLabel,
                    style: WariTypography.labelSmall.copyWith(
                      color: layerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: '',
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Text(marker.title, style: WariTypography.headlineSmall),
          const SizedBox(height: 4),
          if (marker.distanceM != null)
            Text(
              '📍 ${WariFormatters.formatDistance(marker.distanceM!.toDouble())} away · ~${marker.walkMinutes ?? 2} min walk',
              style: WariTypography.bodySmall,
            ),
          const SizedBox(height: WariSpacing.sm),
          Row(
            children: [
              if (marker.availableNow != null)
                WariStatusChip(
                  label: marker.availableNow! ? '✓ Open Now' : 'Closed',
                  color: marker.availableNow! ? WariColors.success : WariColors.danger,
                  dense: true,
                ),
              if (marker.queueMinutes != null) ...[
                const SizedBox(width: WariSpacing.xs),
                WariStatusChip(
                  label: 'Queue: ${marker.queueMinutes}m',
                  color: WariColors.crowdYellow,
                  dense: true,
                ),
              ],
              if (marker.statusLabel != null) ...[
                const SizedBox(width: WariSpacing.xs),
                WariStatusChip(
                  label: marker.statusLabel!,
                  color: layerColor,
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: WariSpacing.base),
          Row(
            children: [
              Expanded(
                child: WariPrimaryButton(
                  label: 'Get Directions',
                  icon: Icons.directions,
                  onPressed: () => _openMapsDirections(marker.latitude, marker.longitude, marker.title),
                ),
              ),
              const SizedBox(width: WariSpacing.sm),
              WariIconButton(
                icon: Icons.share,
                tooltip: 'Share',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location copied: ${marker.title}')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMapsDirections(double lat, double lon, String title) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('$title, $lat,$lon')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
