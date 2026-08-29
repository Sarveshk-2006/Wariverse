import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/home_provider.dart';
import '../../../navigation/app_routes.dart';

/// Weather advisory banner card rendered on Home when active weather warnings exist.
class WeatherAlertCard extends StatelessWidget {
  const WeatherAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final alerts = homeProvider.weather?.alerts ?? [];

    if (alerts.isEmpty) return const SizedBox.shrink();

    final alert = alerts.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: WariSpacing.base),
      child: WariAccentCard(
        accentColor: WariColors.warning,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.alertDetail,
          arguments: alert.alertType,
        ),
        child: Row(
          children: [
            const Text('⛈️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: WariSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.alertType,
                    style: WariTypography.titleMedium.copyWith(
                      color: WariColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(alert.message, style: WariTypography.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
