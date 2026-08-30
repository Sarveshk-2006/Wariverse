import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/ngo_distribution_provider.dart';
import '../../providers/user_provider.dart';
import 'create_distribution_screen.dart';

/// Dedicated Food & Aid Distribution Management Screen for NGO Mobile Portal.
class NgoFoodDistributionScreen extends StatefulWidget {
  const NgoFoodDistributionScreen({super.key});

  @override
  State<NgoFoodDistributionScreen> createState() => _NgoFoodDistributionScreenState();
}

class _NgoFoodDistributionScreenState extends State<NgoFoodDistributionScreen> {
  String _selectedFilter = 'ALL'; // ALL, MY_NGO, FOOD, WATER, MEDICAL, SHELTER

  @override
  Widget build(BuildContext context) {
    final ngoProvider = Provider.of<NgoDistributionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final ngoUid = user?.userId ?? 'ngo_default';

    // Bind current NGO ID to provider stream if available
    if (user != null && ngoProvider.myNgoDistributions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ngoProvider.bindNgoAccount(user.userId);
      });
    }

    final allDistributions = ngoProvider.activeDistributions;
    final myDistributions = ngoProvider.myNgoDistributions;

    // Filter distributions based on selected chip
    final filtered = (allDistributions.isEmpty ? myDistributions : allDistributions).where((d) {
      if (_selectedFilter == 'MY_NGO') return d.ngoId == ngoUid || d.ngoName.contains(user?.displayName ?? '');
      if (_selectedFilter == 'FOOD') return d.category == DistributionCategory.FOOD;
      if (_selectedFilter == 'WATER') return d.category == DistributionCategory.WATER;
      if (_selectedFilter == 'MEDICAL') return d.category == DistributionCategory.MEDICAL_SUPPLIES || d.category == DistributionCategory.MEDICINE;
      if (_selectedFilter == 'SHELTER') return d.category == DistributionCategory.SHELTER;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Food & Aid Distributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
              );
            },
            tooltip: 'Deploy Aid',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL (${filtered.length})', 'ALL'),
                  const SizedBox(width: 6),
                  _buildFilterChip('MY NGO (${myDistributions.length})', 'MY_NGO', color: WariColors.primary),
                  const SizedBox(width: 6),
                  _buildFilterChip('🍱 FOOD', 'FOOD', color: WariColors.success),
                  const SizedBox(width: 6),
                  _buildFilterChip('💧 WATER', 'WATER', color: WariColors.info),
                  const SizedBox(width: 6),
                  _buildFilterChip('🏥 MEDICAL', 'MEDICAL', color: WariColors.danger),
                  const SizedBox(width: 6),
                  _buildFilterChip('⛺ SHELTER', 'SHELTER', color: WariColors.crowdOrange),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(WariSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: WariColors.primaryLight,
                            child: Icon(Icons.no_food_outlined, size: 36, color: WariColors.primaryDark),
                          ),
                          const SizedBox(height: WariSpacing.base),
                          Text('No Active Distributions Found', style: WariTypography.titleMedium),
                          const SizedBox(height: WariSpacing.xs),
                          Text(
                            'Publish a new food or aid distribution center along the route to support pilgrims.',
                            style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: WariSpacing.md),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WariColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('DEPLOY NEW AID CENTER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(WariSpacing.base),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final isMine = item.ngoId == ngoUid;

                      Color statusColor;
                      switch (item.computedDistributionStatus) {
                        case 'ACTIVE': statusColor = WariColors.success; break;
                        case 'UPCOMING': statusColor = WariColors.info; break;
                        case 'EXPIRED':
                        case 'CLOSED': statusColor = WariColors.danger; break;
                        default: statusColor = WariColors.warning; break;
                      }

                      return WariCard(
                        borderColor: isMine ? WariColors.primary.withValues(alpha: 0.4) : WariColors.border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    WariStatusChip(
                                      label: item.category.name,
                                      color: WariColors.primary,
                                      dense: true,
                                    ),
                                    if (isMine) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: WariColors.info, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('YOUR NGO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                WariStatusChip(
                                  label: item.computedDistributionStatus,
                                  color: statusColor,
                                  dense: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.title, style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              'NGO: ${item.ngoName} • Location: ${item.locationName}',
                              style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                            ),
                            const SizedBox(height: 8),

                            // Serving Capacity Progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Servings: ${item.remainingQuantity} / ${item.quantity} ${item.unit}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: WariColors.primaryDark),
                                ),
                                Text(
                                  '${((item.remainingQuantity / (item.quantity > 0 ? item.quantity : 1)) * 100).toInt()}% Remaining',
                                  style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (item.remainingQuantity / (item.quantity > 0 ? item.quantity : 1)).clamp(0.0, 1.0),
                                backgroundColor: WariColors.primaryLight.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  item.remainingQuantity > 50 ? WariColors.success : WariColors.danger,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 13, color: WariColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM dd, hh:mm a').format(item.createdAt),
                                      style: const TextStyle(fontSize: 10, color: WariColors.textMuted),
                                    ),
                                  ],
                                ),
                                if (isMine && item.computedDistributionStatus == 'ACTIVE')
                                  TextButton.icon(
                                    onPressed: () {
                                      final updated = item.copyWith(
                                        remainingQuantity: 0,
                                        completedAt: DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      );
                                      ngoProvider.createDistribution(updated);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Distribution status updated to CLOSED.')),
                                      );
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 14, color: WariColors.danger),
                                    label: const Text('Close Center', style: TextStyle(color: WariColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDistributionScreen()),
          );
        },
        backgroundColor: WariColors.primary,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Deploy Aid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Color color = WariColors.primary}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
    );
  }
}
