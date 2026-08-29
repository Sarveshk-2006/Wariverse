import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/home_provider.dart';
import '../../../navigation/app_routes.dart';

/// Cards showing nearest food & water points matching the web home section.
class NearbyServicesSection extends StatelessWidget {
  const NearbyServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final food = homeProvider.nearbyFood.firstOrNull;
    final water = homeProvider.nearbyWater.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Nearest Services',
          subtitle: 'Real-time distance and queue estimates',
        ),
        const SizedBox(height: WariSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nearest Food
            Expanded(
              child: WariCard(
                onTap: food != null
                    ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.serviceDetail,
                          arguments: food.name,
                        )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🍛', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Nearest Annadan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: WariColors.foodColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.sm),
                    if (food != null) ...[
                      Text(
                        food.name,
                        style: WariTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${WariFormatters.formatDistance(food.distanceM?.toDouble() ?? 150)} · ${food.estimatedQueueMinutes}m queue',
                        style: WariTypography.caption,
                      ),
                      const SizedBox(height: WariSpacing.xs),
                      WariStatusChip(
                        label: food.availableNow ? 'Open Now' : 'Closed',
                        color: food.availableNow ? WariColors.success : WariColors.danger,
                        dense: true,
                      ),
                    ] else
                      Text('Locating food...', style: WariTypography.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(width: WariSpacing.sm),
            // Nearest Water
            Expanded(
              child: WariCard(
                onTap: water != null
                    ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.serviceDetail,
                          arguments: water.name,
                        )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💧', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Nearest Water',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: WariColors.waterColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.sm),
                    if (water != null) ...[
                      Text(
                        water.name,
                        style: WariTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${WariFormatters.formatDistance(water.distanceM?.toDouble() ?? 120)} · ${water.waterType}',
                        style: WariTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: WariSpacing.xs),
                      ServiceStatusChip(
                        status: ServiceStatus.available,
                        dense: true,
                      ),
                    ] else
                      Text('Locating water...', style: WariTypography.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
