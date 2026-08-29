import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/varkari_health_provider.dart';
import '../../repositories/weather_repository.dart';
import '../../services/api_service.dart';

/// Varkari Health Shield heat and dehydration risk awareness dashboard screen.
class VarkariHealthShieldScreen extends StatelessWidget {
  const VarkariHealthShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<VarkariHealthProvider>(
      create: (_) => VarkariHealthProvider(
        weatherRepository: WeatherRepository(apiService),
      )..loadHealthRisk(),
      child: const _VarkariHealthShieldContent(),
    );
  }
}

class _VarkariHealthShieldContent extends StatelessWidget {
  const _VarkariHealthShieldContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VarkariHealthProvider>(context);
    final risk = provider.currentRisk;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Varkari Health Shield (आरोग्य सुरक्षा)'),
        actions: [
          IconButton(
            tooltip: 'Refresh Health Risk',
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadHealthRisk(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (risk?.isDemo ?? true)
            const OfflineBanner(message: 'Demo Mode — Environmental Heat & Dehydration Awareness'),

          Expanded(
            child: provider.isLoading
                ? _buildLoading()
                : provider.hasError
                    ? WariErrorState(
                        message: provider.errorMessage ?? 'Unable to load health risk.',
                        onRetry: () => provider.loadHealthRisk(),
                      )
                    : risk == null
                        ? const WariEmptyState(
                            icon: Icons.thermostat,
                            title: 'Health Risk Unavailable',
                            subtitle: 'Weather data could not be retrieved.',
                          )
                        : _buildBody(context, risk),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: WariSpacing.sm),
        child: WariSkeletonCard(height: 120),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VarkariHealthRisk risk) {
    final isExtreme = risk.isExtremeHeat;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Disclaimer Banner
          Container(
            padding: const EdgeInsets.all(WariSpacing.xs),
            decoration: BoxDecoration(
              color: WariColors.slate100,
              borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
              border: Border.all(color: WariColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: WariColors.textMuted),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Text(
                    'AI-assisted environmental risk awareness tool. Not a medical diagnosis system.',
                    style: WariTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // Weather Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Temperature',
                  value: '${risk.temperatureCelsius.toStringAsFixed(1)}°C',
                  icon: Icons.thermostat,
                  color: isExtreme ? WariColors.danger : WariColors.primary,
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: _buildMetricCard(
                  title: 'Humidity',
                  value: '${risk.humidityPercent.toStringAsFixed(0)}%',
                  icon: Icons.water_drop,
                  color: WariColors.info,
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: _buildMetricCard(
                  title: 'Heat Index',
                  value: risk.heatRiskLevel.name,
                  icon: Icons.warning_amber,
                  color: isExtreme ? WariColors.danger : WariColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.base),

          // Top Prominent Heat Warning Banner (>38°C or High Risk)
          WariCard(
            borderColor: isExtreme ? WariColors.danger : WariColors.warning,
            borderWidth: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isExtreme ? Icons.dangerous : Icons.warning,
                          color: isExtreme ? WariColors.danger : WariColors.warning,
                          size: 24,
                        ),
                        const SizedBox(width: WariSpacing.xs),
                        Text(
                          isExtreme ? '⚠️ EXTREME HEAT WARNING' : 'HEAT & DEHYDRATION ADVISORY',
                          style: WariTypography.titleMedium.copyWith(
                            color: isExtreme ? WariColors.danger : WariColors.warningDark,
                          ),
                        ),
                      ],
                    ),
                    WariStatusChip(
                      label: risk.heatRiskLevel.name,
                      color: isExtreme ? WariColors.danger : WariColors.warning,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  risk.advisoryMessage,
                  style: WariTypography.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          const SectionHeader(
            title: 'Your Risk Levels (आरोग्य परिस्थिती)',
            subtitle: 'Real-time environmental and procession activity assessment',
          ),
          const SizedBox(height: WariSpacing.sm),

          // Risk Breakdown Cards
          _buildRiskItemCard(
            title: '🌡 Heat Risk (उष्णता धोका)',
            level: risk.heatRiskLevel,
            desc: 'Environmental ambient heat exposure',
          ),
          const SizedBox(height: WariSpacing.xs),
          _buildRiskItemCard(
            title: '💧 Dehydration Risk (निर्जलीकरण धोका)',
            level: risk.dehydrationRiskLevel,
            desc: 'Humidity & fluid loss probability',
          ),
          const SizedBox(height: WariSpacing.xs),
          _buildRiskItemCard(
            title: '🚶 Fatigue Risk (थकवा धोका)',
            level: risk.fatigueRiskLevel,
            desc: 'Procession marching duration and physical exertion',
          ),
          const SizedBox(height: WariSpacing.base),

          const SectionHeader(
            title: 'What You Should Do (शिफारस कृती)',
            subtitle: 'Recommended preventive safety measures along the route',
          ),
          const SizedBox(height: WariSpacing.sm),

          // Proximity & Action Grid Buttons connected to existing app capabilities
          Row(
            children: [
              Expanded(
                child: WariSecondaryButton(
                  label: '💧 Find Water',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: WariSecondaryButton(
                  label: '🛑 Take a Rest',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Row(
            children: [
              Expanded(
                child: WariSecondaryButton(
                  label: '🏥 Medical Help',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: WariPrimaryButton(
                  label: '🆘 Emergency SOS',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.base),

          // Proximity Info Bar
          WariCard(
            borderColor: WariColors.border,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Nearest Water Point', style: WariTypography.caption),
                    Text('${risk.distanceToNearestWaterKm} km', style: WariTypography.titleMedium),
                  ],
                ),
                Container(height: 30, width: 1, color: WariColors.border),
                Column(
                  children: [
                    Text('Nearest Medical Camp', style: WariTypography.caption),
                    Text('${risk.distanceToNearestMedicalKm} km', style: WariTypography.titleMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return WariCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title, style: WariTypography.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: WariTypography.titleSmall.copyWith(color: color, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItemCard({
    required String title,
    required VarkariHealthRiskLevel level,
    required String desc,
  }) {
    Color badgeColor = WariColors.success;
    if (level == VarkariHealthRiskLevel.MODERATE) badgeColor = WariColors.warning;
    if (level == VarkariHealthRiskLevel.HIGH || level == VarkariHealthRiskLevel.CRITICAL) badgeColor = WariColors.danger;

    return WariCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WariTypography.titleSmall),
                Text(desc, style: WariTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: WariSpacing.xs),
          WariStatusChip(
            label: level.displayName,
            color: badgeColor,
            dense: true,
          ),
        ],
      ),
    );
  }
}
