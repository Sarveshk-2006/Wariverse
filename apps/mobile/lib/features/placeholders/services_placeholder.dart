import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';

class ServicesPlaceholder extends StatelessWidget {
  const ServicesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(WariSpacing.base),
      children: [
        const SectionHeader(title: 'Pilgrim Services', subtitle: 'Annadan, Water, Medical, Toilets, Shelters'),
        const SizedBox(height: WariSpacing.base),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: WariSpacing.base,
          crossAxisSpacing: WariSpacing.base,
          children: [
            ServiceIconBadge(
              category: ServiceCategory.food,
              label: 'Annadan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Annadan Seva'),
            ),
            ServiceIconBadge(
              category: ServiceCategory.water,
              label: 'Water',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Water Points'),
            ),
            ServiceIconBadge(
              category: ServiceCategory.medical,
              label: 'Medical',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Medical Camps'),
            ),
            ServiceIconBadge(
              category: ServiceCategory.toilet,
              label: 'Toilets',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Sanitation'),
            ),
            ServiceIconBadge(
              category: ServiceCategory.shelter,
              label: 'Shelters',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Relief Shelters'),
            ),
            ServiceIconBadge(
              category: ServiceCategory.wellness,
              label: 'Wellness',
              onTap: () => Navigator.pushNamed(context, AppRoutes.serviceDetail, arguments: 'Foot Care'),
            ),
          ],
        ),
      ],
    );
  }
}
