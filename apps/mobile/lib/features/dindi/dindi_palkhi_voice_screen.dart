import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/dindi_audio_provider.dart';
import '../../repositories/dindi_audio_repository.dart';
import '../../services/api_service.dart';
import '../../services/audio_session_service.dart';

/// Palkhi Voice live audio stream and devotional audio hub screen.
class DindiPalkhiVoiceScreen extends StatelessWidget {
  const DindiPalkhiVoiceScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<DindiAudioProvider>(
      create: (_) => DindiAudioProvider(
        repository: DindiAudioRepository(apiService),
        audioService: DemoAudioSessionService(),
      ),
      child: _DindiPalkhiVoiceContent(overrideDindiId: dindiId),
    );
  }
}

class _DindiPalkhiVoiceContent extends StatefulWidget {
  const _DindiPalkhiVoiceContent({this.overrideDindiId});

  final String? overrideDindiId;

  @override
  State<_DindiPalkhiVoiceContent> createState() => _DindiPalkhiVoiceContentState();
}

class _DindiPalkhiVoiceContentState extends State<_DindiPalkhiVoiceContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAudio();
    });
  }

  void _loadAudio() {
    final dindiProvider = Provider.of<DindiProvider>(context, listen: false);
    final audioProvider = Provider.of<DindiAudioProvider>(context, listen: false);

    final targetId = widget.overrideDindiId ?? dindiProvider.currentDindi?.id ?? 'dindi-001';
    audioProvider.loadAudioSession(targetId);
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<DindiProvider>(context);
    final audioProvider = Provider.of<DindiAudioProvider>(context);

    final currentDindi = dindiProvider.currentDindi;
    final hasJoined = dindiProvider.hasJoinedDindi;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Palkhi Voice (पालखी व्हॉइस)'),
      ),
      body: Column(
        children: [
          if (dindiProvider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Live Dindi Audio Broadcast & Offline Abhangavali'),

          Expanded(
            child: !hasJoined && widget.overrideDindiId == null
                ? _buildNonMemberGate(context)
                : _buildAudioBody(context, provider: audioProvider, dindi: currentDindi),
          ),
        ],
      ),
    );
  }

  Widget _buildNonMemberGate(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: WariCard(
          borderColor: WariColors.warning,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: WariColors.warningLight,
                child: Icon(Icons.mic_off, color: WariColors.primaryDark, size: 32),
              ),
              const SizedBox(height: WariSpacing.base),
              Text(
                'Palkhi Voice Audio Stream',
                style: WariTypography.headlineSmall,
              ),
              const SizedBox(height: WariSpacing.xs),
              Text(
                'Join an official Wari Dindi to listen to live leader kirtan broadcasts and route announcements.',
                style: WariTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.base),
              WariPrimaryButton(
                label: 'Join a Dindi (दिंडीत सामील व्हा)',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.dindiJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBody(
    BuildContext context, {
    required DindiAudioProvider provider,
    required Dindi? dindi,
  }) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 140),
        ),
      );
    }

    final session = provider.activeSession;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Audio Broadcast Banner Card
          if (session != null) ...[
            WariCard(
              borderColor: WariColors.primary,
              borderWidth: 2,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.graphic_eq, color: WariColors.primary, size: 24),
                          const SizedBox(width: WariSpacing.xs),
                          Text('PALKHI VOICE STREAM', style: WariTypography.titleMedium),
                        ],
                      ),
                      WariStatusChip(
                        label: provider.isAudioJoined ? '🎭 DEMO AUDIO' : session.status.statusBadge,
                        color: provider.isAudioJoined ? WariColors.warning : WariColors.primary,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: WariSpacing.sm),

                  Text(
                    session.title,
                    style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Host: ${session.hostName} (${session.hostRole})',
                    style: WariTypography.bodySmall,
                  ),
                  const SizedBox(height: WariSpacing.xs),

                  Text(
                    session.description,
                    style: WariTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: WariSpacing.base),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 16, color: WariColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${session.listenerCount} Varkaris listening',
                        style: WariTypography.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: WariSpacing.base),

                  if (provider.isConnecting)
                    const CircularProgressIndicator()
                  else if (provider.isAudioJoined)
                    WariSecondaryButton(
                      label: 'Leave Audio Stream (ऑडिओ सोडा)',
                      onPressed: () => provider.leaveLiveAudio(),
                    )
                  else
                    WariPrimaryButton(
                      label: 'Join Live Audio (ऑडिओ ऐका)',
                      onPressed: () => provider.joinLiveAudio(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),
          ],

          // Banner CTA to Offline Abhangavali
          WariCard(
            borderColor: WariColors.accent,
            onTap: () => Navigator.pushNamed(context, AppRoutes.abhangavali),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(WariSpacing.xs),
                  decoration: BoxDecoration(
                    color: WariColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.menu_book, color: WariColors.accent, size: 28),
                ),
                const SizedBox(width: WariSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline Abhangavali (अभंगगाथा)', style: WariTypography.titleMedium),
                      Text(
                        'Read & search Marathi devotional hymns without internet',
                        style: WariTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: WariColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          const SectionHeader(
            title: 'Today\'s Broadcast Schedule (आजची सत्रे)',
            subtitle: 'Devotional kirtan & official Dindi announcements',
          ),
          const SizedBox(height: WariSpacing.sm),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.todaySchedule.length,
            itemBuilder: (context, index) {
              final sch = provider.todaySchedule[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: WariSpacing.sm),
                child: WariCard(
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: WariColors.primary, size: 20),
                      const SizedBox(width: WariSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sch.title, style: WariTypography.titleSmall),
                            Text('${sch.hostName} · ${sch.description}', style: WariTypography.caption),
                          ],
                        ),
                      ),
                      WariStatusChip(
                        label: sch.status.name,
                        color: sch.status == DindiAudioStatus.LIVE ? WariColors.success : WariColors.slate500,
                        dense: true,
                      ),
                    ],
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
