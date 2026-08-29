import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/services_provider.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';

class NgoDashboard extends StatelessWidget {
  const NgoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<ServicesProvider>(
      create: (_) => ServicesProvider(
        serviceRepo: ServiceRepository(apiService),
      )..loadServices(),
      child: Consumer<ServicesProvider>(
        builder: (context, provider, _) {
          final services = provider.filteredServices;
          final foodItems = services.where((s) => s.categoryKey == 'food').toList();
          final shelterItems = services.where((s) => s.categoryKey == 'shelters').toList();

          return Scaffold(
            backgroundColor: WariColors.background,
            body: Column(
              children: [
                const RoleDashboardHeader(
                  role: UserRole.NGO,
                  subtitle: 'Annadan, water logistics & shelter distribution coordination',
                  badgeText: 'RESOURCE COORDINATION',
                  badgeColor: WariColors.success,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(WariSpacing.base),
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: WariSpacing.sm,
                        crossAxisSpacing: WariSpacing.sm,
                        childAspectRatio: 1.6,
                        children: [
                          MetricCard(label: 'Food Centres', value: '${foodItems.length}', icon: Icons.restaurant, color: WariColors.foodColor),
                          MetricCard(label: 'Water Stations', value: '5', icon: Icons.water_drop, color: WariColors.waterColor),
                          MetricCard(label: 'Free Shelter Spots', value: '250', icon: Icons.home, color: WariColors.shelterColor),
                          MetricCard(label: 'Help Requests', value: '3', icon: Icons.volunteer_activism, color: WariColors.warning),
                        ],
                      ),
                      const SizedBox(height: WariSpacing.base),

                      Text('🍛 Annadan Food Distribution Status', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      ...foodItems.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                            child: WariCard(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.name, style: WariTypography.titleSmall),
                                      if (f.subtext != null) Text(f.subtext!, style: WariTypography.caption),
                                    ],
                                  ),
                                  WariStatusChip(
                                    label: f.availableNow ? 'OPEN' : 'CLOSED',
                                    color: f.availableNow ? WariColors.success : WariColors.danger,
                                    dense: true,
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: WariSpacing.base),

                      Text('🏠 Relief Shelter Capacity', style: WariTypography.titleSmall),
                      const SizedBox(height: WariSpacing.xs),

                      ...shelterItems.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: WariSpacing.xs),
                            child: WariCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.name, style: WariTypography.titleSmall),
                                      WariStatusChip(label: '${s.capacity ?? 100} SPOTS', color: WariColors.shelterColor, dense: true),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(s.subtext ?? 'Available shelter spots for pilgrims', style: WariTypography.bodySmall),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
