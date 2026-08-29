import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/unified_service_item.dart';
import '../../../providers/nearby_services_provider.dart';
import '../../../providers/map_provider.dart';
import '../../../core/utils/nearby_services_engine.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';

/// Real-Time Location-Based Nearby Services Section rendered on Varkari Home Dashboard.
class NearbyServicesSection extends StatelessWidget {
  final VoidCallback? onOpenMap;

  const NearbyServicesSection({super.key, this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyServicesProvider>(context);
    final services = nearbyProvider.nearbyServices;
    final activeCat = nearbyProvider.activeCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Title & Network Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.near_me_rounded, color: WariColors.primary, size: 22),
                SizedBox(width: WariSpacing.xs),
                Text('Nearby Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            _buildNetworkStatusChip(nearbyProvider.networkStatus),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Essential facilities near your location.',
          style: TextStyle(fontSize: 11, color: WariColors.textSecondary),
        ),
        const SizedBox(height: WariSpacing.sm),

        // Auto-Expansion Alert Banner
        if (nearbyProvider.autoExpandedRadius) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: WariColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WariColors.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: WariColors.accent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Search area expanded to ${nearbyProvider.activeRadiusTier.label} to locate available facilities.',
                    style: const TextStyle(fontSize: 10, color: WariColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.sm),
        ],

        // Category Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(context, nearbyProvider, 'ALL', 'All Services', Icons.grid_view),
              _buildCategoryChip(context, nearbyProvider, 'MEDICAL', 'Medical', Icons.local_hospital),
              _buildCategoryChip(context, nearbyProvider, 'FOOD', 'Food & Annadan', Icons.restaurant),
              _buildCategoryChip(context, nearbyProvider, 'WATER', 'Water', Icons.water_drop),
              _buildCategoryChip(context, nearbyProvider, 'SHELTER', 'Shelter', Icons.home),
              _buildCategoryChip(context, nearbyProvider, 'TOILETS', 'Toilets', Icons.wc),
              _buildCategoryChip(context, nearbyProvider, 'SAFETY', 'Safety & Help', Icons.security),
              _buildCategoryChip(context, nearbyProvider, 'TRANSPORT', 'Transport', Icons.directions_bus),
              _buildCategoryChip(context, nearbyProvider, 'OTHER', 'Other Aid', Icons.card_giftcard),
            ],
          ),
        ),
        const SizedBox(height: WariSpacing.md),

        // Content Area: Location Unavailable / Loading / Empty / Services List
        if (nearbyProvider.isLocationUnavailable)
          WariCard(
            child: Padding(
              padding: const EdgeInsets.all(WariSpacing.md),
              child: Column(
                children: [
                  const Icon(Icons.location_disabled_rounded, color: WariColors.warning, size: 36),
                  const SizedBox(height: 8),
                  const Text('Location Unavailable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Enable GPS location on your device to discover nearby medical camps, food distribution, and water points.',
                    style: TextStyle(fontSize: 11, color: WariColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => nearbyProvider.refresh(),
                    icon: const Icon(Icons.my_location, size: 14),
                    label: const Text('Enable Location / Refresh GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (nearbyProvider.isLoading && services.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: WariSpacing.lg),
            child: WariLoadingIndicator(message: 'Locating nearby facilities from live GPS...'),
          )
        else if (services.isEmpty)
          WariCard(
            child: Padding(
              padding: const EdgeInsets.all(WariSpacing.md),
              child: Column(
                children: [
                  const Icon(Icons.manage_search_rounded, color: WariColors.textMuted, size: 36),
                  const SizedBox(height: 8),
                  Text('No $activeCat services found in nearby search area.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Expand your search radius or select another service category.', style: TextStyle(fontSize: 11, color: WariColors.textMuted), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => nearbyProvider.setSearchRadiusTier(SearchRadiusTier.routeWide),
                    icon: const Icon(Icons.zoom_out_map, size: 14),
                    label: const Text('Expand Search Radius (15km)', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length > 5 ? 5 : services.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final item = services[i];
              return _buildServiceCard(context, item);
            },
          ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    NearbyServicesProvider provider,
    String key,
    String label,
    IconData icon,
  ) {
    final isSelected = provider.activeCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : WariColors.primary),
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : WariColors.textPrimary)),
        selected: isSelected,
        selectedColor: WariColors.primary,
        onSelected: (val) {
          if (val) provider.setActiveCategory(key);
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, UnifiedServiceItem item) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    return WariCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Category Icon Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    WariStatusChip(
                      label: item.availableNow ? 'Available Now' : 'Closed',
                      color: item.availableNow ? WariColors.success : WariColors.textMuted,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.categoryLabel, style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
                if (item.subtext != null)
                  Text(item.subtext!, style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                const SizedBox(height: 6),

                // Distance & Walk Minutes Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, size: 14, color: WariColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${item.distanceM ?? 150}m away (${item.walkMinutes ?? 2} min walk)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WariColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        mapProvider.focusOnServiceAndRoute(item.latitude, item.longitude, item.name, item.categoryKey);
                        if (onOpenMap != null) {
                          onOpenMap!();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Directions to ${item.name} set on Live Map.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Get Directions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStatusChip(NearbyNetworkStatus status) {
    Color color;
    String label;
    switch (status) {
      case NearbyNetworkStatus.live:
        color = WariColors.success;
        label = 'LIVE GPS STREAM';
        break;
      case NearbyNetworkStatus.syncing:
        color = WariColors.warning;
        label = 'SYNCING GPS';
        break;
      case NearbyNetworkStatus.offline:
        color = WariColors.danger;
        label = 'OFFLINE CACHED';
        break;
    }
    return WariStatusChip(label: label, color: color, dense: true);
  }
}
