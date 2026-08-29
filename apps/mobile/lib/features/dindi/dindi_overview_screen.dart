import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/dindi_repository.dart';
import '../../services/api_service.dart';
import 'widgets/dindi_card.dart';

/// Foundational Dindi Overview Screen for WariVerse AI.
class DindiOverviewScreen extends StatelessWidget {
  const DindiOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<DindiProvider>(
      create: (_) => DindiProvider(
        repository: DindiRepository(apiService),
      )..loadDindis(),
      child: const _DindiOverviewContent(),
    );
  }
}

class _DindiOverviewContent extends StatelessWidget {
  const _DindiOverviewContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('My Dindi Operations (माझी दिंडी)'),
        actions: [
          IconButton(
            tooltip: 'Scan Dindi QR',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dindiJoin),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Showing official Wari route Dindi groups'),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadDindis(),
              color: WariColors.primary,
              child: _buildBody(context, provider, user?.userId ?? 'varkari-001', user?.displayName ?? 'Pilgrim'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DindiProvider provider, String userId, String userName) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 120),
        ),
      );
    }

    if (provider.hasError) {
      return WariErrorState(
        message: provider.errorMessage ?? 'Unable to load Dindis.',
        onRetry: () => provider.loadDindis(),
      );
    }

    final dindis = provider.dindis;
    final currentDindi = provider.currentDindi;
    final pass = provider.currentPass;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan Dindi QR Banner Card
          WariCard(
            borderColor: WariColors.accent,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WariSpacing.xs),
                  decoration: BoxDecoration(
                    color: WariColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: WariColors.accent, size: 24),
                ),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join via Leader QR (QR स्कॅन)', style: WariTypography.titleMedium),
                      Text(
                        'Scan official QR displayed by Dindi Pramukh to activate pass',
                        style: WariTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: WariSpacing.xs),
                WariSecondaryButtonInline(
                  label: 'Scan QR',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.dindiJoin),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // Joined Active Dindi Banner
          if (provider.hasJoinedDindi && currentDindi != null) ...[
            WariCard(
              borderColor: WariColors.primary,
              borderWidth: 1.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: WariColors.primaryDark, size: 22),
                          const SizedBox(width: WariSpacing.xs),
                          Text('Active Dindi Membership', style: WariTypography.titleMedium),
                        ],
                      ),
                      const WariStatusChip(
                        label: 'MEMBER',
                        color: WariColors.primaryDark,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: WariSpacing.xs),
                  Text(
                    currentDindi.name,
                    style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
                  ),
                  Text(
                    'Pramukh: ${currentDindi.leaderName} · Current Halt: ${currentDindi.currentHalt}',
                    style: WariTypography.bodySmall,
                  ),
                  const SizedBox(height: WariSpacing.sm),

                  if (pass != null) ...[
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.dindiPass),
                      child: Container(
                        padding: const EdgeInsets.all(WariSpacing.xs),
                        decoration: BoxDecoration(
                          color: WariColors.surface,
                          borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                          border: Border.all(color: WariColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code, size: 16, color: WariColors.primary),
                            const SizedBox(width: WariSpacing.xs),
                            Expanded(
                              child: Text(
                                'Pass ID: ${pass.passId}',
                                style: WariTypography.labelSmall,
                              ),
                            ),
                            const WariStatusChip(
                              label: 'VIEW DIGITAL PASS',
                              color: WariColors.success,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.xs),
                  ],

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.varkariHealthShield,
                          ),
                          icon: const Icon(Icons.thermostat, size: 16, color: WariColors.primary),
                          label: Text(
                            'Health Shield (आरोग्य)',
                            style: WariTypography.labelSmall.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.dindiPalkhiVoice,
                            arguments: currentDindi.id,
                          ),
                          icon: const Icon(Icons.graphic_eq, size: 16, color: WariColors.primary),
                          label: Text(
                            'Palkhi Voice (व्हॉइस)',
                            style: WariTypography.labelSmall.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.dindiCommunity,
                            arguments: currentDindi.id,
                          ),
                          icon: const Icon(Icons.forum, size: 16, color: WariColors.primary),
                          label: Text(
                            'Community (खाजगी चर्चा)',
                            style: WariTypography.labelSmall.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.dindiLiveRoute,
                            arguments: currentDindi.id,
                          ),
                          icon: const Icon(Icons.navigation, size: 16, color: WariColors.primary),
                          label: Text(
                            'Live Route (थेट रस्ता)',
                            style: WariTypography.labelSmall.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.dindiSchedule,
                            arguments: currentDindi.id,
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16, color: WariColors.primary),
                          label: Text(
                            'Schedule (वेळापत्रक)',
                            style: WariTypography.labelSmall.copyWith(color: WariColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => provider.leaveDindi(),
                          child: Text(
                            'Leave',
                            style: WariTypography.caption.copyWith(color: WariColors.danger, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),
          ],

          const SectionHeader(
            title: 'Wari Dindi Groups (दिंडी मंडळ)',
            subtitle: 'Discover and join official devotional procession batches along the route',
          ),
          const SizedBox(height: WariSpacing.sm),

          if (dindis.isEmpty)
            const WariEmptyState(
              icon: Icons.groups_outlined,
              title: 'No Active Dindis Available',
              subtitle: 'Check back shortly as procession batches update location.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dindis.length,
              itemBuilder: (context, index) {
                final dindi = dindis[index];
                final isJoined = currentDindi?.id == dindi.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: WariSpacing.sm),
                  child: DindiCard(
                    dindi: dindi,
                    isJoined: isJoined,
                    onJoin: !isJoined
                        ? () => provider.joinDindi(dindi.id, userId, userName: userName)
                        : null,
                    onSchedule: () => Navigator.pushNamed(
                      context,
                      AppRoutes.dindiSchedule,
                      arguments: dindi.id,
                    ),
                    onLiveRoute: () => Navigator.pushNamed(
                      context,
                      AppRoutes.dindiLiveRoute,
                      arguments: dindi.id,
                    ),
                    onCommunity: () => Navigator.pushNamed(
                      context,
                      AppRoutes.dindiCommunity,
                      arguments: dindi.id,
                    ),
                    onVoice: () => Navigator.pushNamed(
                      context,
                      AppRoutes.dindiPalkhiVoice,
                      arguments: dindi.id,
                    ),
                    onHealthShield: () => Navigator.pushNamed(
                      context,
                      AppRoutes.varkariHealthShield,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
