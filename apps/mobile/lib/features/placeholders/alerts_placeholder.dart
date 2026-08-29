import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';

class AlertsPlaceholder extends StatelessWidget {
  const AlertsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
        const SectionHeader(title: 'Active Safety Alerts', subtitle: 'Live crowd & weather advisories'),
        const SizedBox(height: WariSpacing.sm),
        WariAccentCard(
          accentColor: WariColors.danger,
          onTap: () => Navigator.pushNamed(context, AppRoutes.alertDetail, arguments: 'Vitthal Mandir Ghat Surge'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vitthal Mandir Ghat', style: WariTypography.titleMedium),
                  const AlertSeverityChip(severity: AlertSeverity.critical, dense: true),
                ],
              ),
              const SizedBox(height: WariSpacing.xs),
              Text('Extreme crowd density reported (92%). Divert pilgrims via Bypass.', style: WariTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
