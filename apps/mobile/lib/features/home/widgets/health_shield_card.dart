import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../navigation/app_routes.dart';

/// Compact pilgrim home screen card displaying AI-assisted heat & dehydration risk summary.
class HealthShieldCard extends StatelessWidget {
  const HealthShieldCard({
    super.key,
    required this.healthRisk,
    this.onTap,
  });

  final VarkariHealthRisk healthRisk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isHigh = healthRisk.heatRiskLevel == VarkariHealthRiskLevel.HIGH ||
        healthRisk.heatRiskLevel == VarkariHealthRiskLevel.CRITICAL;

    return WariCard(
      borderColor: isHigh ? WariColors.warning : WariColors.border,
      borderWidth: isHigh ? 1.5 : 1.0,
      onTap: onTap ?? () => Navigator.pushNamed(context, AppRoutes.varkariHealthShield),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(WariSpacing.xs),
                      decoration: BoxDecoration(
                        color: isHigh ? WariColors.warningLight : WariColors.primaryLight,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.thermostat,
                        color: isHigh ? WariColors.warning : WariColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: WariSpacing.xs),
                    Expanded(
                      child: Text(
                        'HEALTH SHIELD (आरोग्य)',
                        style: WariTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              WariStatusChip(
                label: healthRisk.heatRiskLevel.name,
                color: isHigh ? WariColors.warning : WariColors.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          Row(
            children: [
              Text(
                '${healthRisk.temperatureCelsius.toStringAsFixed(1)}°C',
                style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
              ),
              const SizedBox(width: WariSpacing.sm),
              Expanded(
                child: Text(
                  healthRisk.advisoryMessage,
                  style: WariTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💧 Hydrate · 🛑 Rest',
                style: WariTypography.labelSmall.copyWith(color: WariColors.primaryDark),
              ),
              Text(
                'VIEW HEALTH SHIELD →',
                style: WariTypography.caption.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
