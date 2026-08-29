import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/ngo_distribution_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import '../ngo/create_distribution_screen.dart';
import 'widgets/role_dashboard_header.dart';
import 'widgets/metric_card.dart';
import '../ngo/widgets/ngo_emergency_dialog.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ServicesProvider>(
          create: (_) => ServicesProvider(
            serviceRepo: ServiceRepository(apiService),
          ),
        ),
        ChangeNotifierProvider<NgoDistributionProvider>(
          create: (_) => NgoDistributionProvider(),
        ),
      ],
      child: const _NgoDashboardContent(),
    );
  }
}

class _NgoDashboardContent extends StatefulWidget {
  const _NgoDashboardContent();

  @override
  State<_NgoDashboardContent> createState() => _NgoDashboardContentState();
}

class _NgoDashboardContentState extends State<_NgoDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user != null) {
          Provider.of<NgoDistributionProvider>(context, listen: false).bindNgoAccount(user.userId);
        }
        Provider.of<ServicesProvider>(context, listen: false).loadServices();
      }
    });
  }

  void _showUpdateQuantityDialog(BuildContext context, ResourceDistribution dist) {
    final qtyController = TextEditingController(text: '${dist.remainingQuantity}');
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: Text('Update Remaining Quantity: ${dist.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Initial Quantity: ${dist.quantity} ${dist.unit}', style: WariTypography.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Remaining Quantity (${dist.unit})',
                prefixIcon: const Icon(Icons.inventory_2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQty = int.tryParse(qtyController.text.trim());
              if (newQty != null && user != null) {
                await Provider.of<NgoDistributionProvider>(context, listen: false).updateQuantity(dist.id, user.userId, newQty);
                if (dContext.mounted) Navigator.of(dContext).pop();
              }
            },
            child: const Text('Save Quantity'),
          ),
        ],
      ),
    );
  }

  void _showUpdateQueueDialog(BuildContext context, ResourceDistribution dist) {
    final queueController = TextEditingController(text: '${dist.currentQueue ?? 0}');
    final waitController = TextEditingController(text: '${dist.estimatedQueueMinutes ?? 5}');
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;

    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        title: Text('Update Queue Metrics: ${dist.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: queueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current Queue Count (People)', prefixIcon: Icon(Icons.people)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estimated Wait (Minutes)', prefixIcon: Icon(Icons.timer)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final q = int.tryParse(queueController.text.trim()) ?? 0;
              final w = int.tryParse(waitController.text.trim()) ?? 5;
              if (user != null) {
                await Provider.of<NgoDistributionProvider>(context, listen: false).updateQueue(dist.id, user.userId, q, w);
                if (dContext.mounted) Navigator.of(dContext).pop();
              }
            },
            child: const Text('Update Queue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NgoDistributionProvider>(
      builder: (context, distProvider, _) {
        final distributions = distProvider.myNgoDistributions.isNotEmpty
            ? distProvider.myNgoDistributions
            : distProvider.activeDistributions;

        final activeCount = distributions.where((d) => d.isActive).length;
        final totalServed = distributions.fold<int>(0, (sum, d) => sum + (d.quantity - d.remainingQuantity));
        final foodAvailable = distributions
            .where((d) => d.category == DistributionCategory.FOOD && d.isActive)
            .fold<int>(0, (sum, d) => sum + d.remainingQuantity);
        final waterAvailable = distributions
            .where((d) => d.category == DistributionCategory.WATER && d.isActive)
            .fold<int>(0, (sum, d) => sum + d.remainingQuantity);

        final user = Provider.of<UserProvider>(context, listen: false).currentUser;

        return Scaffold(
          backgroundColor: WariColors.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
              );
            },
            backgroundColor: WariColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('+ Create Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              RoleDashboardHeader(
                role: UserRole.NGO,
                subtitle: 'Annadan, Water Logistics & Shelter Distribution Coordination',
                badgeText: 'RESOURCE COORDINATION',
                badgeColor: WariColors.success,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: WariSpacing.base, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const NgoEmergencyDialog(),
                          );
                        },
                        icon: const Icon(Icons.warning_amber_rounded, size: 16),
                        label: const Text('Report Site Hazard / SOS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WariColors.danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
                        MetricCard(label: 'Active Distributions', value: '$activeCount', icon: Icons.campaign, color: WariColors.primary),
                        MetricCard(label: 'People Served', value: '$totalServed', icon: Icons.group, color: WariColors.success),
                        MetricCard(label: 'Food Available', value: '$foodAvailable meals', icon: Icons.restaurant, color: WariColors.foodColor),
                        MetricCard(label: 'Water Available', value: '$waterAvailable bottles', icon: Icons.water_drop, color: WariColors.waterColor),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.base),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('📦 Active NGO Resource Distributions', style: WariTypography.titleSmall),
                        TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Create New'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.xs),

                    if (distributions.isEmpty)
                      const WariCard(
                        child: Text('No active distributions. Tap "+ Create Distribution" to publish aid.'),
                      )
                    else
                      ...distributions.map((d) {
                        final availRatio = (d.remainingQuantity / (d.quantity > 0 ? d.quantity : 1)).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
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
                                          Icon(d.category.icon, color: d.category.color, size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(d.title, style: WariTypography.titleSmall, overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    ),
                                    WariStatusChip(
                                      label: d.computedAvailabilityStatus,
                                      color: d.computedAvailabilityStatus == 'AVAILABLE'
                                          ? WariColors.success
                                          : d.computedAvailabilityStatus == 'FINISHED'
                                              ? WariColors.danger
                                              : WariColors.warning,
                                      dense: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('📍 ${d.locationName}', style: WariTypography.bodySmall),
                                const SizedBox(height: 4),

                                LinearProgressIndicator(
                                  value: availRatio,
                                  backgroundColor: WariColors.slate100,
                                  color: d.category.color,
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Remaining: ${d.remainingQuantity} / ${d.quantity} ${d.unit}',
                                      style: WariTypography.caption,
                                    ),
                                    Text(
                                      'Queue: ${d.currentQueue ?? 0} people (${d.estimatedQueueMinutes ?? 0}m wait)',
                                      style: WariTypography.caption,
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('Quantity', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showUpdateQuantityDialog(context, d),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.queue, size: 14),
                                      label: const Text('Queue', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _showUpdateQueueDialog(context, d),
                                    ),
                                    const SizedBox(width: 6),
                                    if (d.computedAvailabilityStatus != 'FINISHED')
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: WariColors.success, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                        onPressed: () async {
                                          if (user != null) {
                                            await distProvider.completeDistribution(d.id, user.userId);
                                          }
                                        },
                                        child: const Text('Complete', style: TextStyle(fontSize: 12, color: Colors.white)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
