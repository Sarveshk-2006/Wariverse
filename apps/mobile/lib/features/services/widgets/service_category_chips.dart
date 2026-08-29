import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../models/map_marker_item.dart';
import '../../../providers/services_provider.dart';

/// Horizontal category filter chip bar for Services Hub.
class ServiceCategoryChips extends StatelessWidget {
  const ServiceCategoryChips({super.key});

  static const List<({String key, String label, IconData icon})> _categories = [
    (key: 'all', label: 'All Services', icon: Icons.grid_view),
    (key: 'food', label: 'Annadan Food', icon: Icons.restaurant),
    (key: 'water', label: 'Water Station', icon: Icons.water_drop),
    (key: 'medical', label: 'Medical Camp', icon: Icons.local_hospital),
    (key: 'toilets', label: 'Toilets', icon: Icons.wc),
    (key: 'shelters', label: 'Shelters', icon: Icons.home),
    (key: 'wellness', label: 'Wellness', icon: Icons.spa),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServicesProvider>(context);
    final active = provider.activeCategory;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: WariSpacing.base),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = active == cat.key;
          final color = MapMarkerItem.getLayerColor(cat.key);

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              selected: isSelected,
              avatar: Icon(
                cat.icon,
                size: 14,
                color: isSelected ? color : WariColors.slate500,
              ),
              label: Text(cat.label),
              labelStyle: WariTypography.labelSmall.copyWith(
                color: isSelected ? color : WariColors.slate700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
              backgroundColor: WariColors.surface,
              selectedColor: color.withValues(alpha: 0.15),
              side: BorderSide(
                color: isSelected ? color : WariColors.border,
                width: isSelected ? 1.5 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              onSelected: (_) => provider.setActiveCategory(cat.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
