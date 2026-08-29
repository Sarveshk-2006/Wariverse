import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../repositories/dindi_repository.dart';
import '../../services/api_service.dart';
import 'widgets/schedule_timeline_card.dart';

/// Micro-schedule and itinerary screen for a Dindi procession unit.
class DindiScheduleScreen extends StatelessWidget {
  const DindiScheduleScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<DindiProvider>(
      create: (_) {
        final provider = DindiProvider(repository: DindiRepository(apiService));
        final id = dindiId ?? 'dindi-001';
        provider.loadDindis().then((_) => provider.selectDindi(id));
        return provider;
      },
      child: const _DindiScheduleContent(),
    );
  }
}

class _DindiScheduleContent extends StatelessWidget {
  const _DindiScheduleContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DindiProvider>(context);
    final dindi = provider.currentDindi;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text(dindi != null ? '${dindi.name} Itinerary' : 'Today\'s Schedule (आजचे वेळापत्रक)'),
      ),
      body: Column(
        children: [
          if (provider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Live schedule estimated based on route itinerary'),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (dindi != null) await provider.loadSchedule(dindi.id);
              },
              color: WariColors.primary,
              child: _buildBody(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DindiProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 100),
        ),
      );
    }

    if (provider.hasError) {
      return WariErrorState(
        message: provider.errorMessage ?? 'Unable to load Dindi schedule.',
        onRetry: () {
          if (provider.currentDindi != null) provider.loadSchedule(provider.currentDindi!.id);
        },
      );
    }

    final schedule = provider.scheduleItems;
    final currentItem = provider.currentScheduleItem;
    final nextItem = provider.nextScheduleItem;

    if (schedule.isEmpty) {
      return const WariEmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No Schedule Available',
        subtitle: 'No itinerary entries recorded for today\'s procession.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          WariCard(
            borderColor: WariColors.primary,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WariSpacing.xs),
                  decoration: BoxDecoration(
                    color: WariColors.primaryLight,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.auto_stories, color: WariColors.primaryDark, size: 24),
                ),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.currentDindi?.name ?? 'Wari Procession Dindi',
                        style: WariTypography.titleMedium,
                      ),
                      Text(
                        'Route: ${provider.currentDindi?.routeSection ?? 'Alandi - Pandharpur'}',
                        style: WariTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // CURRENT EVENT SPOTLIGHT
          if (currentItem != null) ...[
            const SectionHeader(
              title: 'CURRENT EVENT (चालू कार्यक्रम)',
              subtitle: 'Active halt or procession action right now',
            ),
            const SizedBox(height: WariSpacing.xs),
            ScheduleTimelineCard(
              item: currentItem,
              onViewOnMap: currentItem.hasLocation
                  ? () => Navigator.pushNamed(context, AppRoutes.map)
                  : null,
            ),
            const SizedBox(height: WariSpacing.base),
          ],

          // NEXT EVENT SPOTLIGHT
          if (nextItem != null) ...[
            const SectionHeader(
              title: 'NEXT HALT (पुढील थांबा)',
              subtitle: 'Upcoming scheduled stop along the route',
            ),
            const SizedBox(height: WariSpacing.xs),
            ScheduleTimelineCard(
              item: nextItem,
              onViewOnMap: nextItem.hasLocation
                  ? () => Navigator.pushNamed(context, AppRoutes.map)
                  : null,
            ),
            const SizedBox(height: WariSpacing.base),
          ],

          // FULL TODAY'S JOURNEY TIMELINE
          const SectionHeader(
            title: 'TODAY\'S JOURNEY (आजचा संपूर्ण प्रवास)',
            subtitle: 'Chronological timeline of halts and events',
          ),
          const SizedBox(height: WariSpacing.xs),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final item = schedule[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: WariSpacing.sm),
                child: ScheduleTimelineCard(
                  item: item,
                  onViewOnMap: item.hasLocation
                      ? () => Navigator.pushNamed(context, AppRoutes.map)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
