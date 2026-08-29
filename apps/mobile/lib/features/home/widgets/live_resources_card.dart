import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/ngo_distribution_provider.dart';
import '../../../navigation/app_routes.dart';

/// Realtime Varkari Resource Discovery widget showing live NGO deployments.
class LiveResourcesCard extends StatelessWidget {
  const LiveResourcesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ngoProvider = Provider.of<NgoDistributionProvider>(context);
    final activeDeployments = ngoProvider.filteredDistributions;

    if (activeDeployments.isEmpty) {
      return WariCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'LIVE WARI RESOURCES',
              subtitle: 'Real-time NGO Aid & Distribution Posts',
              actionLabel: 'Explore Map',
            ),
            const SizedBox(height: WariSpacing.sm),
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.slate50,
                borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                border: Border.all(color: WariColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: WariColors.textSecondary, size: 20),
                  SizedBox(width: WariSpacing.xs),
                  Expanded(
                    child: Text(
                      'No active NGO aid deployments nearby right now. Check back shortly for food, water, or medical camps.',
                      style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: WariColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  Text('LIVE WARI RESOURCES', style: WariTypography.titleMedium),
                ],
              ),
              WariStatusChip(
                label: '${activeDeployments.length} Active',
                color: WariColors.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time NGO aid camps, food, water & medical distribution',
            style: WariTypography.caption.copyWith(color: WariColors.textSecondary),
          ),
          const SizedBox(height: WariSpacing.md),

          // Horizontal list of live resource cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: activeDeployments.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(right: WariSpacing.sm),
                  child: SizedBox(
                    height: 175,
                    child: _buildResourceTile(context, d),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceTile(BuildContext context, ResourceDistribution d) {
    final cat = d.category;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(WariSpacing.sm),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
        border: Border.all(color: cat.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cat.color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cat.color.withValues(alpha: 0.15),
                child: Icon(cat.icon, size: 16, color: cat.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: WariTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      d.ngoName,
                      style: WariTypography.caption.copyWith(color: WariColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Metrics
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: WariColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  d.locationName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: WariColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${d.remainingQuantity} ${d.unit} remaining',
                  style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (d.estimatedQueueMinutes != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 12, color: WariColors.textSecondary),
                const SizedBox(width: 2),
                Text(
                  '${d.estimatedQueueMinutes}m wait',
                  style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.map, arguments: {'layer': 'all'});
                  },
                  icon: const Icon(Icons.map, size: 14),
                  label: const Text('View Map', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cat.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
