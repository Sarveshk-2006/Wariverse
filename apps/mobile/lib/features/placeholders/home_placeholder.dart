import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.currentRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WariCard(
            color: WariColors.primaryLight.withValues(alpha: 0.12),
            borderColor: WariColors.primary,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WariSpacing.sm),
                  decoration: const BoxDecoration(
                    color: WariColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.temple_hindu, color: Colors.white, size: 24),
                ),
                const SizedBox(width: WariSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${userProvider.currentUser?.displayName ?? "Pilgrim"}',
                        style: WariTypography.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active Role: ${role.displayName}',
                        style: WariTypography.caption.copyWith(color: WariColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          const SectionHeader(
            title: 'Quick Actions',
            subtitle: 'Navigation verification shortcuts',
          ),
          const SizedBox(height: WariSpacing.sm),

          Wrap(
            spacing: WariSpacing.sm,
            runSpacing: WariSpacing.sm,
            children: [
              WariSecondaryButtonInline(
                label: 'Crowd Zone Detail',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.crowdDetail, arguments: 'Vitthal Mandir Ghat'),
              ),
              WariSecondaryButtonInline(
                label: 'Emergency SOS Status',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.sosStatus, arguments: 'sos1'),
              ),
              WariSecondaryButtonInline(
                label: 'Role Dashboard',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.roleDashboard),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xl),

          WariCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phase E - Navigation Shell Active', style: WariTypography.titleMedium),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'Primary tab bar navigation and role-switching are operational. Ready for detailed dashboard widgets in Phase F.',
                  style: WariTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
