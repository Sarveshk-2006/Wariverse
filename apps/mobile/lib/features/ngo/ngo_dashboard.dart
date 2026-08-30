import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env_config.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/ngo_distribution_provider.dart';
import '../../providers/user_provider.dart';
import 'create_distribution_screen.dart';
import 'ngo_food_distribution_screen.dart';

/// Clean, Apple-style NGO Operational Home Dashboard for Mobile Client.
class NgoDashboard extends StatelessWidget {
  const NgoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final ngoProvider = Provider.of<NgoDistributionProvider>(context);
    final user = userProvider.currentUser;

    final ngoName = user?.displayName ?? 'Sansthan NGO Partner';
    final activeDeployments = ngoProvider.activeDistributions;

    // Calculate total serving capacity
    final totalServings = activeDeployments.fold<int>(0, (sum, item) => sum + item.quantity);
    final foodCount = activeDeployments.where((d) => d.category.name == 'FOOD').length;
    final waterCount = activeDeployments.where((d) => d.category.name == 'WATER').length;
    final medicalCount = activeDeployments.where((d) => d.category.name == 'MEDICAL').length;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('NGO Operational Command'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: const [
                Icon(Icons.fiber_manual_record, color: WariColors.success, size: 10),
                SizedBox(width: 4),
                Text('LIVE SYNC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WariColors.success)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(WariSpacing.base),
        children: [
          // 1. NGO Identity Header Card
          WariCard(
            borderColor: WariColors.primary.withValues(alpha: 0.3),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: WariColors.primaryLight,
                  child: Icon(Icons.volunteer_activism_rounded, color: WariColors.primaryDark, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ngoName, style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.verified_rounded, color: WariColors.success, size: 14),
                          SizedBox(width: 4),
                          Text('Verified NGO Aid Provider', style: TextStyle(fontSize: 11, color: WariColors.success, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // 2. Primary Web Portal CTA Card
          WariCard(
            borderColor: WariColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.laptop_mac_rounded, color: WariColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text('Detailed Operations Web Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WariColors.primaryDark)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Access advanced inventory tracking, volunteer assignments, and logistics dispatch in the web operations console.',
                  style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(EnvConfig.ngoDashboardUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 18),
                    label: const Text('Open NGO Operations Portal →', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // 3. Live Operational Summary Metrics Grid
          Text('Live Aid Summary', style: WariTypography.titleSmall),
          const SizedBox(height: WariSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Active Deployments',
                  value: '${activeDeployments.length}',
                  icon: Icons.storefront_rounded,
                  color: WariColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Serving Capacity',
                  value: '$totalServings',
                  icon: Icons.restaurant_rounded,
                  color: WariColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Food Hubs',
                  value: '$foodCount',
                  icon: Icons.rice_bowl_rounded,
                  color: WariColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Water & Medical',
                  value: '${waterCount + medicalCount}',
                  icon: Icons.local_hospital_rounded,
                  color: WariColors.crowdOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.base),

          // 4. Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WariColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 18),
                  label: const Text('Deploy Aid Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NgoFoodDistributionScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: WariColors.primary),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, color: WariColors.primaryDark, size: 18),
                  label: const Text('All Distributions', style: TextStyle(fontWeight: FontWeight.bold, color: WariColors.primaryDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.base),

          // 5. Active Distribution Preview Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Route Deployments', style: WariTypography.titleSmall),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NgoFoodDistributionScreen()),
                  );
                },
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: WariColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),

          if (activeDeployments.isEmpty)
            const WariEmptyState(
              icon: Icons.soup_kitchen_outlined,
              title: 'No Active Deployments',
              subtitle: 'Tap "Deploy Aid Center" to publish a food or water distribution point along the pilgrimage route.',
            )
          else
            ...activeDeployments.take(3).map((item) => WariCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: WariColors.primaryLight,
                      child: Icon(
                        item.category.name == 'FOOD'
                            ? Icons.restaurant
                            : (item.category.name == 'WATER' ? Icons.water_drop : Icons.medical_services),
                        color: WariColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('NGO: ${item.ngoName} • Capacity: ${item.quantity} ${item.unit}', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                    trailing: WariStatusChip(
                      label: item.computedDistributionStatus,
                      color: item.computedDistributionStatus == 'ACTIVE' ? WariColors.success : WariColors.warning,
                      dense: true,
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, color: WariColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
