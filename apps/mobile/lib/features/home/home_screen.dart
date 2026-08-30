import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../providers/home_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_actions_grid.dart';
import '../dindi/widgets/virtual_dindi_home_card.dart';
import '../dindi/create_virtual_dindi_screen.dart';
import '../dindi/join_virtual_dindi_modal.dart';
import '../dindi/virtual_dindi_detail_screen.dart';

/// Full WariVerse AI Varkari Home Dashboard view.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<HomeProvider>(
      create: (_) => HomeProvider(
        crowdRepo: CrowdRepository(apiService),
        weatherRepo: WeatherRepository(apiService),
        serviceRepo: ServiceRepository(apiService),
        sosRepo: SosRepository(apiService),
        adminRepo: AdminRepository(apiService),
      ),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<HomeProvider>(context, listen: false).loadDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      body: RefreshIndicator(
        onRefresh: () => homeProvider.refresh(),
        color: WariColors.primary,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(WariSpacing.base),
          children: [
            // A. Top App Bar Header
            const HomeHeader(),
            const SizedBox(height: 12),

            // B. Location & Safety Status Bar Card
            const LocationSafetyStatusCard(),
            const SizedBox(height: 14),

            // C. My Dindi Card (Real Firestore Data)
            VirtualDindiHomeCard(
              onCreatePressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateVirtualDindiScreen()));
              },
              onJoinPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const JoinVirtualDindiModal(),
                );
              },
              onOpenMapPressed: () {
                Navigator.pushNamed(context, '/map');
              },
              onDetailPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VirtualDindiDetailScreen()));
              },
            ),
            const SizedBox(height: 14),

            // D. Primary Quick Actions (2x2 Grid)
            const QuickActionsGrid(),
            const SizedBox(height: 16),

            // E. Contextual Nearby Services Summary Card
            const ContextualNearbyCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Compact Status Bar displaying live GPS location status and active Dindi connectivity.
class LocationSafetyStatusCard extends StatelessWidget {
  const LocationSafetyStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final activeDindi = dindiProvider.activeDindi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WariColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // GPS Location Active Badge
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: WariColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GPS Active',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 16, color: WariColors.border),
          const SizedBox(width: 12),

          // Dindi Connection Badge
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: activeDindi != null ? WariColors.success : WariColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activeDindi != null ? 'Connected: ${activeDindi.name}' : 'Not Joined to Dindi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeDindi != null ? WariColors.successDark : WariColors.warningDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contextual Nearby Services Summary Card.
class ContextualNearbyCard extends StatelessWidget {
  const ContextualNearbyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WariColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WariColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WariColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.mapPin, color: WariColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Essential Services Nearby',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.primaryDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Water Kiosks, Medical Camps & Annadhan within 500m',
                  style: TextStyle(fontSize: 11, color: WariColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/services'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('View All', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
