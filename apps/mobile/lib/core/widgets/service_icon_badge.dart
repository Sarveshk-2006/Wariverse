import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Service category definitions matching the web app icons and colors.
enum ServiceCategory {
  food,
  water,
  medical,
  toilet,
  shelter,
  wellness,
  sos,
  crowd,
  route,
}

/// Returns the saffron-brand color for each service category.
Color serviceCategoryColor(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.food:
      return WariColors.foodColor;
    case ServiceCategory.water:
      return WariColors.waterColor;
    case ServiceCategory.medical:
      return WariColors.medicalColor;
    case ServiceCategory.toilet:
      return WariColors.toiletColor;
    case ServiceCategory.shelter:
      return WariColors.shelterColor;
    case ServiceCategory.wellness:
      return WariColors.wellnessColor;
    case ServiceCategory.sos:
      return WariColors.sosColor;
    case ServiceCategory.crowd:
      return WariColors.primary;
    case ServiceCategory.route:
      return WariColors.info;
  }
}

/// Returns the emoji icon for each service category (matches web emoji style).
String serviceCategoryEmoji(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.food:
      return '\uD83C\uDF5B'; // 🍛
    case ServiceCategory.water:
      return '\uD83D\uDCA7'; // 💧
    case ServiceCategory.medical:
      return '\uD83C\uDFE5'; // 🏥
    case ServiceCategory.toilet:
      return '\uD83D\uDEB9'; // 🚹
    case ServiceCategory.shelter:
      return '\uD83C\uDFE0'; // 🏠
    case ServiceCategory.wellness:
      return '\uD83C\uDF3F'; // 🌿
    case ServiceCategory.sos:
      return '\uD83D\uDEA8'; // 🚨
    case ServiceCategory.crowd:
      return '\uD83D\uDC65'; // 👥
    case ServiceCategory.route:
      return '\uD83D\uDDFA'; // 🗺️
  }
}

/// Returns a Material icon for each service category.
IconData serviceCategoryIcon(ServiceCategory category) {
  switch (category) {
    case ServiceCategory.food:
      return Icons.restaurant;
    case ServiceCategory.water:
      return Icons.water_drop;
    case ServiceCategory.medical:
      return Icons.local_hospital;
    case ServiceCategory.toilet:
      return Icons.wc;
    case ServiceCategory.shelter:
      return Icons.home;
    case ServiceCategory.wellness:
      return Icons.spa;
    case ServiceCategory.sos:
      return Icons.emergency;
    case ServiceCategory.crowd:
      return Icons.people;
    case ServiceCategory.route:
      return Icons.route;
  }
}

/// Circular icon badge for service categories — used in quick actions, map legend, etc.
class ServiceIconBadge extends StatelessWidget {
  const ServiceIconBadge({
    super.key,
    required this.category,
    this.size = 48.0,
    this.onTap,
    this.label,
  });

  final ServiceCategory category;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = serviceCategoryColor(category);
    final icon = serviceCategoryIcon(category);
    final iconSize = size * 0.45;

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );

    if (onTap != null) {
      badge = GestureDetector(onTap: onTap, child: badge);
    }

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(height: WariSpacing.xs),
          Text(
            label!,
            style: WariTypography.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return badge;
  }
}

