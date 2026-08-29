import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../models/map_marker_item.dart';
import '../../../providers/map_provider.dart';

/// Floating category filter bar for the interactive map.
class MapFilterBar extends StatelessWidget {
  const MapFilterBar({super.key});

  static const List<({String key, String label, IconData icon})> _filters = [
    (key: 'all', label: 'Everything', icon: Icons.map),
    (key: 'food', label: 'Food', icon: Icons.restaurant),
    (key: 'water', label: 'Water', icon: Icons.water_drop),
    (key: 'medical', label: 'Medical', icon: Icons.local_hospital),
    (key: 'toilets', label: 'Toilets', icon: Icons.wc),
    (key: 'shelters', label: 'Shelter', icon: Icons.home),
    (key: 'wellness', label: 'Wellness', icon: Icons.spa),
    (key: 'sos', label: 'Emergency', icon: Icons.emergency),
  ];

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final activeLayer = mapProvider.activeLayer;

    return Container(
      margin: const EdgeInsets.all(WariSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: WariSpacing.sm,
        vertical: WariSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WariColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
        border: Border.all(color: WariColors.border),
        boxShadow: [
          BoxShadow(
            color: WariColors.slate900.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = activeLayer == f.key;
            final color = MapMarkerItem.getLayerColor(f.key);

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: GestureDetector(
                onTap: () => mapProvider.setActiveLayer(f.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : WariColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : WariColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 14, color: isSelected ? color : WariColors.slate500),
                      const SizedBox(width: 4),
                      Text(
                        f.label,
                        style: WariTypography.chipLabel.copyWith(
                          color: isSelected ? color : WariColors.slate700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
