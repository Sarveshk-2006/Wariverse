import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/unified_service_item.dart';

/// Comprehensive detail sheet for any pilgrim service facility.
class ServiceDetailBottomSheet extends StatelessWidget {
  const ServiceDetailBottomSheet({
    super.key,
    required this.item,
    required this.onClose,
    this.onViewOnMap,
  });

  final UnifiedServiceItem item;
  final VoidCallback onClose;
  final VoidCallback? onViewOnMap;

  @override
  Widget build(BuildContext context) {
    return WariCard(
      elevation: WariSpacing.elevationLg,
      radius: WariSpacing.radiusLg,
      borderColor: item.color.withValues(alpha: 0.4),
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
                  Icon(item.icon, size: 18, color: item.color),
                  const SizedBox(width: WariSpacing.xs),
                  Text(
                    item.categoryLabel,
                    style: WariTypography.labelSmall.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Text(item.name, style: WariTypography.headlineSmall),
          if (item.subtext != null) ...[
            const SizedBox(height: 2),
            Text(item.subtext!, style: WariTypography.bodySmall),
          ],
          const SizedBox(height: WariSpacing.sm),

          Row(
            children: [
              WariStatusChip(
                label: item.availableNow ? '✓ OPEN NOW' : 'CLOSED',
                color: item.availableNow ? WariColors.success : WariColors.danger,
                dense: true,
              ),
              if (item.queueMinutes != null) ...[
                const SizedBox(width: WariSpacing.xs),
                WariStatusChip(
                  label: 'Queue: ${item.queueMinutes}m',
                  color: item.queueMinutes! > 15 ? WariColors.danger : WariColors.success,
                  dense: true,
                ),
              ],
              if (item.capacity != null) ...[
                const SizedBox(width: WariSpacing.xs),
                WariStatusChip(
                  label: 'Cap: ${item.capacity}',
                  color: WariColors.slate600,
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: WariSpacing.base),

          if (item.distanceM != null)
            Text(
              '📍 Distance: ${WariFormatters.formatDistance(item.distanceM!.toDouble())} · Approx ${item.walkMinutes ?? 2} min walk',
              style: WariTypography.bodySmall,
            ),
          const SizedBox(height: WariSpacing.sm),

          if (item.tags.isNotEmpty) ...[
            Text('Amenities & Services:', style: WariTypography.labelSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  labelStyle: WariTypography.caption.copyWith(fontSize: 10),
                  backgroundColor: WariColors.slate100,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: WariSpacing.base),
          ],

          Row(
            children: [
              Expanded(
                child: WariPrimaryButton(
                  label: 'Get Directions',
                  icon: Icons.directions,
                  onPressed: () => _openMapsDirections(item.latitude, item.longitude, item.name),
                ),
              ),
              if (onViewOnMap != null) ...[
                const SizedBox(width: WariSpacing.sm),
                Expanded(
                  child: WariSecondaryButton(
                    label: 'View on Map',
                    icon: Icons.map,
                    onPressed: onViewOnMap,
                  ),
                ),
              ],
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
