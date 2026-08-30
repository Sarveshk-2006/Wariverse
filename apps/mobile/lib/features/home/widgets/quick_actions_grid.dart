import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../navigation/app_routes.dart';

/// Senior-Friendly 2x2 Primary Quick Action Grid for Varkari Home Launcher.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions (द्रुत कृती)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WariColors.textPrimary),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85,
          children: [
            // 1. 🆘 SOS Emergency (Prominent Red Gradient Card)
            _BigActionCard(
              icon: LucideIcons.siren,
              title: 'SOS Emergency',
              subtitle: '1-Tap Instant Help',
              color: WariColors.danger,
              isEmergency: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.sosStatus, arguments: 'new-sos'),
            ),
            // 2. 🗺 Live Map
            _BigActionCard(
              icon: LucideIcons.map,
              title: 'Live Map',
              subtitle: 'Route & Halts',
              color: WariColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.map),
            ),
            // 3. 🏥 Nearby Services
            _BigActionCard(
              icon: LucideIcons.heartPulse,
              title: 'Nearby Services',
              subtitle: 'Water, Food, Care',
              color: WariColors.info,
              onTap: () => Navigator.pushNamed(context, AppRoutes.services),
            ),
            // 4. 👥 My Dindi
            _BigActionCard(
              icon: LucideIcons.users,
              title: 'My Dindi',
              subtitle: 'Group & Roster',
              color: WariColors.success,
              onTap: () => Navigator.pushNamed(context, AppRoutes.dindi),
            ),
          ],
        ),
      ],
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isEmergency
                ? const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isEmergency ? null : WariColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmergency ? WariColors.danger : WariColors.border,
              width: isEmergency ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isEmergency ? WariColors.danger.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEmergency ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEmergency ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? Colors.white : WariColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isEmergency ? Colors.white70 : WariColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
