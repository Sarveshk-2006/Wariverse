import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/home_provider.dart';
import '../../repositories/repositories_exports.dart';
import '../../services/api_service.dart';
import 'widgets/home_header.dart';
import 'widgets/crowd_status_card.dart';
import 'widgets/weather_alert_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/nearby_services_card.dart';
import 'widgets/role_summary_card.dart';

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

    if (homeProvider.isLoading) {
      return Scaffold(
        backgroundColor: WariColors.background,
        body: ListView(
          padding: const EdgeInsets.all(WariSpacing.base),
          children: const [
            WariSkeletonCard(height: 120),
            SizedBox(height: WariSpacing.base),
            WariSkeletonCard(height: 80),
            SizedBox(height: WariSpacing.base),
            WariSkeletonCard(height: 160),
          ],
        ),
      );
    }

    if (homeProvider.hasError && homeProvider.weather == null) {
      return Scaffold(
        backgroundColor: WariColors.background,
        body: WariErrorState(
          message: homeProvider.errorMessage ?? 'Unable to connect to WariVerse servers.',
          onRetry: () => homeProvider.loadDashboardData(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WariColors.background,
      body: RefreshIndicator(
        onRefresh: () => homeProvider.refresh(),
        color: WariColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(WariSpacing.base),
          children: const [
            HomeHeader(),
            SizedBox(height: WariSpacing.base),
            RoleSummaryCard(),
            SizedBox(height: WariSpacing.base),
            CrowdStatusCard(),
            SizedBox(height: WariSpacing.base),
            WeatherAlertCard(),
            QuickActionsGrid(),
            SizedBox(height: WariSpacing.base),
            NearbyServicesSection(),
            SizedBox(height: WariSpacing.xl),
          ],
        ),
      ),
    );
  }
}
