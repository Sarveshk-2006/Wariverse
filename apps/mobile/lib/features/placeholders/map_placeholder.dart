import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WariColors.slate100,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ServiceIconBadge(category: ServiceCategory.route, size: 64),
            const SizedBox(height: WariSpacing.base),
            Text('Interactive Wari Map', style: WariTypography.headlineMedium),
            const SizedBox(height: WariSpacing.xs),
            Text('Leaflet map & crowd layers will be active in Phase H', style: WariTypography.bodySmall),
            const SizedBox(height: WariSpacing.base),
            WariSecondaryButtonInline(
              label: 'View Sample Service Marker',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.serviceDetail,
                arguments: 'Maharshi Annadan Kendra #1',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
