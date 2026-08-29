import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../providers/home_provider.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import 'widgets/home_header.dart';
import 'widgets/crowd_status_card.dart';
import 'widgets/weather_alert_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/nearby_services_section.dart';
import 'widgets/role_summary_card.dart';
import 'widgets/live_resources_card.dart';
import '../dindi/widgets/virtual_dindi_home_card.dart';
import '../dindi/create_virtual_dindi_screen.dart';
import '../dindi/join_virtual_dindi_modal.dart';
import '../dindi/virtual_dindi_detail_screen.dart';
import '../incidents/widgets/varkari_incident_card.dart';
import '../incidents/report_threat_screen.dart';

/// Full WariVerse AI Home Dashboard view.
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
          padding: const EdgeInsets.all(WariSpacing.base),
          children: [
            const HomeHeader(),
            const SizedBox(height: WariSpacing.base),
            RoleSummaryCard(),
            const SizedBox(height: WariSpacing.base),
            VarkariIncidentCard(
              onReportPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportThreatScreen()));
              },
            ),
            const SizedBox(height: WariSpacing.base),
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
            const SizedBox(height: WariSpacing.base),
            const LiveResourcesCard(),
            const SizedBox(height: WariSpacing.base),
            CrowdStatusCard(),
            const SizedBox(height: WariSpacing.base),
            WeatherAlertCard(),
            QuickActionsGrid(),
            const SizedBox(height: WariSpacing.base),
            NearbyServicesSection(),
            const SizedBox(height: WariSpacing.xl),
          ],
        ),
      ),
    );
  }
}
