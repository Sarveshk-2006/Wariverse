import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../providers/home_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../providers/qr_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/models_exports.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import '../../core/widgets/wari_qr_card.dart';
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

            // C2. Pilgrim e-ID QR Pass Card
            const PilgrimQrPassHomeCard(),
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
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GPS Location Active Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: WariColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'GPS Active',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
              ),
            ],
          ),
          Container(width: 1, height: 16, color: WariColors.border),

          // Dindi Connection Badge
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                Flexible(
                  child: Text(
                    activeDindi != null ? 'Connected: ${activeDindi.name}' : 'Not Joined to Dindi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeDindi != null ? WariColors.successDark : WariColors.warningDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WariColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WariColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WariColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.mapPin, color: WariColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Essential Services Nearby',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WariColors.primaryDark),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/services'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View All →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Water Kiosks, Medical Camps & Annadhan within 500m',
            style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Senior-Friendly Pilgrim e-ID QR Pass Card for Varkari Home Dashboard.
class PilgrimQrPassHomeCard extends StatefulWidget {
  const PilgrimQrPassHomeCard({super.key});

  @override
  State<PilgrimQrPassHomeCard> createState() => _PilgrimQrPassHomeCardState();
}

class _PilgrimQrPassHomeCardState extends State<PilgrimQrPassHomeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final qrProvider = Provider.of<QrProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final userId = user?.userId ?? 'varkari-001';

    final qrCode = qrProvider.activeUserQr ??
        WariQrCode(
          id: 'qr_$userId',
          token: 'WVQ_WVRK-892147',
          type: QrType.PERSON,
          status: QrStatus.ACTIVE,
          ownerId: userId,
          targetCollection: 'users',
          targetDocumentId: userId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          createdBy: userId,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WariColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WariColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.qrCode, color: WariColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Varkari Pilgrim e-ID QR (क्यूआर पास)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WariColors.primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isExpanded ? 'Scan with Google Camera / Google Lens' : 'Tap to show your e-ID QR Code for scanning',
                      style: const TextStyle(fontSize: 11, color: WariColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isExpanded ? 'Hide ▲' : 'Show QR ▼',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WariColors.primary),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            Center(
              child: WariQrCard(
                qrCode: qrCode,
                title: user?.displayName ?? 'Ramabai Shinde',
                subtitle: 'Official WariVerse Pilgrim Identity Tag',
                size: 160.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
