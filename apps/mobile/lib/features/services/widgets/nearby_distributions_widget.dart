import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/ngo_distribution_provider.dart';

/// Realtime discovery card widget displaying nearby NGO aid distributions for Varkaris.
class NearbyDistributionsWidget extends StatelessWidget {
  const NearbyDistributionsWidget({super.key});

  void _launchNavigation(double lat, double lng, String label) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDistributionDetails(BuildContext context, ResourceDistribution dist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.radiusLg)),
      ),
      builder: (bContext) => Padding(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: WariColors.slate300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            Row(
              children: [
                Icon(dist.category.icon, color: dist.category.color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dist.title, style: WariTypography.titleMedium),
                      Text(dist.ngoName, style: WariTypography.caption),
                    ],
                  ),
                ),
                WariStatusChip(
                  label: dist.computedAvailabilityStatus,
                  color: dist.computedAvailabilityStatus == 'AVAILABLE' ? WariColors.success : WariColors.warning,
                ),
              ],
            ),
            const Divider(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2, color: WariColors.primary),
              title: Text('Available Quantity: ${dist.remainingQuantity} ${dist.unit}'),
              subtitle: Text('Total Provided: ${dist.quantity} ${dist.unit}'),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place, color: WariColors.primary),
              title: Text(dist.locationName),
              subtitle: Text(dist.address ?? 'Wari Route'),
            ),

            if (dist.instructions != null && dist.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WariSpacing.sm),
                decoration: BoxDecoration(
                  color: WariColors.slate100,
                  borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📢 Gathering Instructions:', style: WariTypography.labelSmall),
                    const SizedBox(height: 4),
                    Text(dist.instructions!, style: WariTypography.bodySmall),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                if (dist.estimatedQueueMinutes != null)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: WariColors.textMuted),
                        const SizedBox(width: 4),
                        Text('Est. Wait: ${dist.estimatedQueueMinutes}m', style: WariTypography.bodySmall),
                      ],
                    ),
                  ),
                if (dist.tokensRequired)
                  const WariStatusChip(label: 'TOKENS REQUIRED', color: WariColors.info, dense: true),
              ],
            ),
            const SizedBox(height: WariSpacing.base),

            ElevatedButton.icon(
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('Get Directions / Navigate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: WariColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.of(bContext).pop();
                _launchNavigation(dist.latitude, dist.longitude, dist.locationName);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NgoDistributionProvider?>(context);
    if (provider == null) {
      return const SizedBox.shrink();
    }
    final items = provider.filteredDistributions;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🍛 Real-Time NGO Aid & Resources', style: WariTypography.titleSmall),
                Text('${items.length} Available', style: WariTypography.caption),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Aid'),
                    selected: provider.selectedCategory == null || provider.selectedCategory == 'ALL',
                    onSelected: (_) => provider.setCategoryFilter('ALL'),
                  ),
                  const SizedBox(width: 6),
                  ...DistributionCategory.values.map((cat) {
                    final isSel = provider.selectedCategory == cat.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 16, color: isSel ? Colors.white : cat.color),
                        label: Text(cat.name),
                        selected: isSel,
                        selectedColor: cat.color,
                        onSelected: (_) => provider.setCategoryFilter(cat.name),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.xs),

            if (items.isEmpty)
              const WariCard(
                child: Text('No active aid distributions match the selected filter.'),
              )
            else
              Column(
                children: items.map((dist) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                    child: WariCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(dist.category.icon, color: dist.category.color, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dist.title, style: WariTypography.titleSmall, overflow: TextOverflow.ellipsis),
                                          Text('By ${dist.ngoName}', style: WariTypography.caption),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              WariStatusChip(
                                label: '${dist.remainingQuantity} ${dist.unit}',
                                color: dist.computedAvailabilityStatus == 'AVAILABLE'
                                    ? WariColors.success
                                    : WariColors.warning,
                                dense: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 14, color: WariColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(dist.locationName, style: WariTypography.bodySmall, overflow: TextOverflow.ellipsis),
                              ),
                              if (dist.estimatedQueueMinutes != null)
                                Text('Wait: ~${dist.estimatedQueueMinutes}m', style: WariTypography.caption),
                            ],
                          ),
                          const Divider(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => _showDistributionDetails(context, dist),
                                child: const Text('[VIEW DETAILS]'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.navigation_outlined, size: 14),
                                label: const Text('NAVIGATE', style: TextStyle(fontSize: 12)),
                                onPressed: () => _launchNavigation(dist.latitude, dist.longitude, dist.locationName),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
  }
}
